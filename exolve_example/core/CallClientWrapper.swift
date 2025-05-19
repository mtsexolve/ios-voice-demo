import SwiftUI
import Foundation
import AVFAudio
import ExolveVoiceSDK
import UIKit

class CallClientWrapper: ObservableObject, RegistrationDelegate, CallsDelegate, AudioRouteDelegate {
    @Published private(set) var calls: [CallData] = []
    @Published private(set) var conferenceActive = false
    @Published private(set) var isSpeakerOn: Bool = false
    @Published private(set) var registrationState: RegistrationState
    @Published private(set) var pushToken: String = ""
    @Published private(set) var versionDescription: String = ""
    @Published private(set) var audioRoutes: [AudioRouteData] = []
    @Published private(set) var currentAudioRoute: String = Strings.AudioRoute
    public private(set) var locationServiceEnabled: Bool = true;

    private(set) var login = ""
    private(set) var password = ""
    private(set) var lastCall = ""

    public static let instance = CallClientWrapper()
    private var communicator: Communicator
    private var callClient: CallClient
    private var durationTimer: Timer?

    private let logtag = "CallClientWrapper:"

    private var activeAppObserver: (any NSObjectProtocol)? = nil

    private init() {
        login = Storage.login
        password = Storage.password
        lastCall = Storage.lastCall
        locationServiceEnabled = Storage.location
        NSLog("\(logtag) location services will be \(locationServiceEnabled ? "en" : "dis")abled")

        let config = ExolveVoiceSDK.Configuration.default()
        config.logConfiguration.logLevel = Storage.logLevel
        config.enableSipTrace = Storage.sipTraces
        config.useSecureConnection = Storage.encryption
        config.callKitConfiguration = CallKitConfiguration.default()
        config.callKitConfiguration?.notifyInForeground = true
        config.callKitConfiguration?.contactSearchHandler = contactSearchHandler
        config.enableDetectLocation = locationServiceEnabled

        if Storage.environment == Strings.Default {
            communicator = Communicator(configuration: config)
            Storage.environment = (!communicator.getVersionInfo().environment.isEmpty) ? communicator.getVersionInfo().environment : Strings.Default
        } else {
            communicator = Communicator(configuration: config, environment:Storage.environment)
        }

        let sdkVersionInfo : VersionInfo = communicator.getVersionInfo()
        versionDescription = "SDK ver.\(sdkVersionInfo.buildVersion) env: \((!sdkVersionInfo.environment.isEmpty) ? sdkVersionInfo.environment : Strings.Default )"
        

        callClient = communicator.callClient()
        registrationState = callClient.registrationState()

        callClient.setRegistrationDelegate(self, with: DispatchQueue.main)
        callClient.setCallsDelegate(self, with: DispatchQueue.main)
        callClient.setAudioRouteDelegate(self)

        communicator.retrieveVoipPushToken { [self] (token: String) in
            NSLog("\(logtag) retrieved voip push token \"\(token)\"")
            pushToken = token
        }

        NotificationCenter.default.addObserver(self,
            selector:#selector(onAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
    }

    func isRegistered() -> Bool {
        return callClient.registrationState() == .RS_NotRegistered
    }

    func register(_ login: String, _ password: String) {
        Storage.login = login
        Storage.password = password
        self.login = login
        self.password = password

        if login.isEmpty || password.isEmpty {
            Alert.show("Error", "No credentials")
            return
        }
        if locationServiceEnabled && LocationAccessProvider.instance.authorizationStatus == .notDetermined {
            LocationAccessProvider.instance.requestAuthorization { [self] in
                callClient.registerUser(login, password: password)
            }
        } else {
            callClient.registerUser(login, password: password)
        }
    }

    func unregister() {
        callClient.unregister()
    }

    func callToNumber(number: String) {
        Storage.lastCall = number
        lastCall = number

        let session = AVAudioSession.sharedInstance()
        switch (session.recordPermission) {
        case AVAudioSession.RecordPermission.undetermined:
            NSLog("\(logtag) request record permission")
            session.requestRecordPermission { [self] (granted: Bool) in
                if granted {
                    NSLog("\(logtag) call to \"\(number)\"")
                    placeCall(number)
                }
            }
            break
        case AVAudioSession.RecordPermission.granted:
            NSLog("\(logtag) call to \"\(number)\"")
                placeCall(number)
            break
        default:
            NSLog("\(logtag) no record permission")
            break
        }
    }

    private func placeCall(_ number: String) {
        if locationServiceEnabled && LocationAccessProvider.instance.authorizationStatus == .notDetermined {
            let action = { [self] in
                NSLog("\(logtag) place deferred call to \(number)")
                callClient.placeCall(number)
            }
            LocationAccessProvider.instance.requestAuthorization(deferredAction: action)
        } else {
            callClient.placeCall(number)
        }
    }

    private func removeCall(_ call: Call!) {
        if let call {
            for (i, stored) in calls.enumerated() {
                if call.identifier == stored.call.identifier {
                    calls.remove(at: i)
                }
            }
        }

        if calls.isEmpty {
            isSpeakerOn = false
        }
    }

    func getAliveCalls() -> [CallData] {
        return calls.filter() {
            $0.state != .CS_Error && $0.state != .CS_Terminated
        }
    }

    func haveCredentials() -> Bool {
        return !login.isEmpty && !password.isEmpty
    }

    func dismissConference() {
        NSLog("\(logtag) dismiss conference")
        let conf = calls.filter() { $0.call.inConference }
        for data in conf {
            data.call.terminate()
        }
    }

    private func updateConferenceState() {
        let prev = conferenceActive
        conferenceActive = false
        for data in calls {
            if data.call.inConference {
                conferenceActive = true
                break
            }
        }

        if conferenceActive != prev {
            NSLog("\(logtag) conference \(conferenceActive ? "assembled" : "dismissed")")
        }
    }

    func setSpeakerOn(_ speakerOn: Bool) {
        callClient.setSpeakerOn(speakerOn)
        isSpeakerOn = callClient.isSpeakerOn()
        NSLog("\(logtag) speaker is on: \(isSpeakerOn)")
    }

    func setAudioRoute(_ routeData: AudioRouteData) {
        callClient.setAudioRoute(routeData)
    }

    func callTransfer(call: Call!, toNumber: String) {
        NSLog("\(logtag) call transfer to number \(toNumber)")
        for stored in calls {
            if call == stored.call {
                call.transfer(toNumber: toNumber)
            }
        }
    }

    func callTransfer(call: Call!, toCall: String) {
        NSLog("\(logtag) call transfer to call \(toCall)")
        for stored in calls {
            if call == stored.call {
                call.transfer(toCall: toCall)
            }
        }
    }

    @objc private func onAudioRouteChange(notification: Notification) {
        NSLog("\(logtag) audio route changed")
        if let value = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt {
            let reason = AVAudioSession.RouteChangeReason(rawValue: value)
            var str: String
            switch reason {
            case .newDeviceAvailable:
                str = "new device available"
            case .oldDeviceUnavailable:
                str = "old device unavailable"
            case .categoryChange:
                str = "audio category changed"
            case .override:
                str = "route overriden"
            case .wakeFromSleep:
                str = "wake from sleep"
            case .noSuitableRouteForCategory:
                str = "no route for the current category"
            case .routeConfigurationChange:
                str = "route configuration changed"
            default:
                str = "unknown"
            }
            NSLog("\(logtag) reason: \(str)")
        }

        let routes = AVAudioSession.sharedInstance().currentRoute.outputs;
        routes.forEach() { NSLog("\(logtag) audio output \($0.portName) as \($0.portType.rawValue)") }
        currentAudioRoute = routes.isEmpty ? Strings.AudioRoute : routes.first!.portType.rawValue
    }

    func enableLocationService(_ enabled: Bool) {
        NSLog("\(logtag) location services \(enabled ? "en" : "dis")abled")
        communicator.configurationManager().setDetectLocationEnabled(enabled)
        locationServiceEnabled = enabled
        Storage.location = enabled
    }

    private func updateCallState(_ call: Call) {
        NSLog("\(logtag) call state: \(call.state.stringValue) for \"\(call.number)\"")
        for stored in calls {
            if call == stored.call {
                stored.state = call.state
            }
        }

        let info = ["call": call, "state": call.state] as [String : Any]
        NotificationCenter.default.post(name: .call, object: nil, userInfo: info)
    }

    private func updateRegistrationState(_ error: RegistrationError? = nil,_ errorMessage: String? = nil) {
        registrationState = callClient.registrationState()
        if let errorMessage = errorMessage {
            NSLog("\(logtag) registration error: \(errorMessage)")
            Alert.show("Error", "\(errorMessage)")
        } else {
            NSLog("\(logtag) registration state: \(registrationState.stringValue)")
        }
    }

    private func checkToggleMeasurements() {
        if calls.filter({ $0.isAlive }).isEmpty {
            if durationTimer != nil {
                durationTimer!.invalidate()
                durationTimer = nil
            }
        } else {
            if durationTimer == nil {
                let increment = { [self] (_: Timer) in
                    calls.forEach { call in
                        call.updateStatistics()
                    }
                }
                durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: increment)
            }
        }
    }

    func getAvailableEnvironments() -> [String] {
        let arr = [Strings.Default] + (Communicator.getAvailableEnvironments() ?? [])
        return arr
    }

    //MARK: audio route delegate here
    internal func routeChanged(_ routes: [AudioRouteData]) {
        audioRoutes = routes
    }

    //MARK: calls delegate here
    internal func callNew(_ call: Call) {
        NSLog("\(logtag) call new")
        calls.append(CallData(call))
        updateCallState(call)
    }

    internal func callConnected(_ call: Call) {
        NSLog("\(logtag) call connected")
        updateCallState(call)
        checkToggleMeasurements()
    }

    internal func callHold(_ call: Call) {
        NSLog("\(logtag) call hold")
        updateCallState(call)
        updateConferenceState()
    }

    internal func callDisconnected(_ call: Call, details: CallDisconnectDetails) {
        NSLog("\(logtag) call disconnected: id: \(call.identifier), duration: \(details.duration), reason: \(details.disconnectReason)")
        updateCallState(call)
        removeCall(call)
        updateConferenceState()
        checkToggleMeasurements()
        let isMissed = call.direction == .CD_Incoming
            && details.duration == 0
            && details.disconnectReason == .DR_EndedByPeer
        if (isMissed) {
            showMissedCallNotification(call.formattedNumber)
        }
    }
    
    private func showMissedCallNotification(_ number: String) {
        let content = UNMutableNotificationContent()
        content.title = "Missed call"
        content.body = "Missed call from \(number)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                NSLog("\(logtag) error while adding notification")
            }
        }
    }

    internal func callError(_ call: Call, error: CallError, message: String) {
        NSLog("\(logtag) call error: \(message)")
        Alert.show("Error", "\(message)")
        updateCallState(call)
        removeCall(call)
        checkToggleMeasurements()
    }
    
    internal func callConnectionLost(_ call: Call) {
        NSLog("\(logtag) call connection lost")
        updateCallState(call)
        updateConferenceState()
    }

    internal func call(_ call: Call, inConference: Bool) {
        NSLog("\(logtag) call \(call.identifier), in conference: \(inConference)")
        updateConferenceState()
    }

    internal func callMuted(_ call: Call) {
        NSLog("\(logtag) call \(call.isMuted ? "" : "un")muted")
        for stored in calls {
            if call == stored.call {
                stored.mute = call.isMuted
                break
            }
        }
    }

    internal func callUserActionRequired(_ call: Call, pendingEvent: CallPendingEvent, requiredAction: CallUserAction) {
        NSLog("\(logtag) action required: \(pendingEvent) \(requiredAction)")

        if pendingEvent == .CPE_IncomingCall {
            if UIApplication.shared.applicationState == .background {
                NSLog("\(logtag) show notification to open the app")
                let content = UNMutableNotificationContent()
                content.title = Strings.NotificationOpenAppTitle
                content.body = Strings.NotificationOpenAppBody
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                Task {
                    do {
                        NSLog("\(logtag) add notification")
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        NSLog("\(logtag) error while adding notification")
                    }
                }
            }
        }

        if pendingEvent == .CPE_AcceptCall {
            let status = LocationAccessProvider.instance.authorizationStatus
            if status == .notDetermined {
                NSLog("\(logtag) authorization required")
                if let data = calls.first(where: { $0.call == call }) {
                    data.locationAccessRequired = true
                    let action = { [self, call] in
                        NSLog("\(logtag) accepting incoming call")
                        calls.forEach() { $0.locationAccessRequired = false}
                        call.accept()
                    }
                    LocationAccessProvider.instance.requestAuthorization(deferredAction: action)
                }
            } else if status == .restricted || status == .denied {
                call.accept() // force SDK to fail on error
            } else if UIApplication.shared.applicationState != .active {
                //not enough permission wait till the application will be active
                NSLog("\(logtag) active app required to accepted the call")
                activeAppObserver = NotificationCenter.default.addObserver(
                    forName: UIScene.didActivateNotification,
                    object: nil,
                    queue: OperationQueue.main) { [self, weak call] _ in
                        call?.accept()
                        if let observer = activeAppObserver {
                            NotificationCenter.default.removeObserver(observer)
                            activeAppObserver = nil
                        }
                    }
            }
        }
    }

    //MARK: registration delegate here
    internal func registered() {
        updateRegistrationState()
        if let callIntent = Storage.callIntent {
            if !callIntent.isEmpty {
                placeCall(callIntent)
            }
            Storage.callIntent = nil
        }
    }

    internal func registering() {
        updateRegistrationState()
    }

    internal func notRegistered() {
        updateRegistrationState()
    }

    internal func offline() {
        updateRegistrationState()
    }

    internal func noConnection() {
        updateRegistrationState()
    }

    internal func registrationError(_ error: RegistrationError, message: String) {
        updateRegistrationState(error, message)
        if (error == RegistrationError.RE_LocationNoAccess) && LocationAccessProvider.instance.authorizationStatus == .notDetermined {
            if UIApplication.shared.applicationState == .active {
                LocationAccessProvider.instance.requestAuthorization(deferredAction: { [self] in
                    callClient.setOffline(false)
                })
            } else {
                NSLog("\(logtag) active app required to activate account")
                activeAppObserver = NotificationCenter.default.addObserver(
                    forName: UIScene.didActivateNotification,
                    object: nil,
                    queue: OperationQueue.main) { [self] _ in
                        LocationAccessProvider.instance.requestAuthorization(deferredAction: { [self] in
                            callClient.setOffline(false)
                        })
                        if let observer = activeAppObserver {
                            NotificationCenter.default.removeObserver(observer)
                            activeAppObserver = nil
                        }
                    }
            }
        }
    }

}


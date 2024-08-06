import SwiftUI
import Foundation
import AVFAudio
import ExolveVoiceSDK
import UIKit

class CallClientWrapper: ObservableObject, RegistrationDelegate, CallsDelegate {
    @Published private(set) var calls: [CallData] = []
    @Published private(set) var conferenceActive = false
    @Published private(set) var isSpeakerOn: Bool = false
    @Published private(set) var registrationState: RegistrationState
    @Published private(set) var pushToken: String = ""
    @Published private(set) var versionDescription: String = ""
    @Published private(set) var currentAudioRoute: String = Strings.AudioRoute
    public private(set) var locationServiceEnabled: Bool = true;

    private(set) var login = ""
    private(set) var password = ""
    private(set) var lastCall = ""

    public static let instance = CallClientWrapper()
    private var communicator: Communicator
    private var callClient: CallClient

    private struct UserKey {
        static let Login = "login"
        static let Password = "password"
        static let LastCall = "last_call"
        static let Location = "location"
    }

    private let logtag = "CallClientWrapper:"

    private init() {
        let prefs = UserDefaults.standard
        login = prefs.string(forKey: UserKey.Login) ?? ""
        password = prefs.string(forKey: UserKey.Password) ?? ""
        lastCall = prefs.string(forKey: UserKey.LastCall) ?? ""
        let useLocation = prefs.object(forKey: UserKey.Location) as? Bool ?? true
        NSLog("\(logtag) location services will be \(useLocation ? "en" : "dis")abled")
        locationServiceEnabled = useLocation

        let config = ExolveVoiceSDK.Configuration.default()
        config?.logConfiguration.logLevel = .LL_Debug
        config?.enableSipTrace = true
        config?.callKitConfiguration = CallKitConfiguration.default()
        config?.callKitConfiguration.notifyInForeground = true
        config?.callKitConfiguration.contactSearchHandler = contactSearchHandler
        config?.enableDetectCallLocation = useLocation

        communicator = Communicator(configuration: config)

        callClient = communicator.callClient()
        registrationState = callClient.registrationState()

        let sdkVersionInfo : VersionInfo = communicator.getVersionInfo()
        versionDescription = "SDK ver.\(sdkVersionInfo.buildVersion) env: \((!sdkVersionInfo.environment.isEmpty) ? sdkVersionInfo.environment : "default" )"

        callClient.setRegistrationDelegate(self, with: DispatchQueue.main)
        callClient.setCallsDelegate(self, with: DispatchQueue.main)

        communicator.retrieveVoipPushToken { [self] (str: String?) in
            let token = str ?? ""
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
        let prefs = UserDefaults.standard
        prefs.set(login, forKey: UserKey.Login);
        prefs.set(password, forKey: UserKey.Password);
        self.login = login
        self.password = password

        if login.isEmpty || password.isEmpty {
            Alert.show("Error", "No credentials")
            return
        }

        callClient.registerUser(login, password: password)
    }

    func unregister() {
        callClient.unregister()
    }

    func callToNumber(number: String) {
        lastCall = number
        UserDefaults.standard.set(number, forKey: UserKey.LastCall);

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
        communicator.configurationManager().setDetectCallLocationEnabled(enabled)
        locationServiceEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: UserKey.Location);
    }

    private func updateCallState(_ call: Call) {
        NSLog("\(logtag) call state: \(call.state.stringValue) for \"\(call.number ?? "null")\"")
        for stored in calls {
            if call == stored.call {
                stored.state = call.state
            }
        }

        let info = ["call": call, "state": call.state] as [String : Any]
        NotificationCenter.default.post(name: .call, object: nil, userInfo: info)
    }

    private func updateRegistrationState(_ error:RegistrationError? = nil,_ errorMessage: String? = nil) {
        registrationState = callClient.registrationState()
        if let error = error, let errorMessage = errorMessage {
            NSLog("\(logtag) registration error: \(error.stringValue), \(errorMessage)")
            Alert.show("Error", "\(error.stringValue)\n\(errorMessage)")
        } else {
            NSLog("\(logtag) registration state: \(registrationState.stringValue)")
        }
    }

    //MARK: calls delegate here
    internal func callNew(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call new")
            calls.append(CallData(call))
            updateCallState(call)
        }
    }

    internal func callConnected(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call connected")
            updateCallState(call)
        }
    }

    internal func callHold(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call hold")
            updateCallState(call)
            updateConferenceState()
        }
    }

    internal func callDisconnected(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call disconnected")
            updateCallState(call)
            removeCall(call)
            updateConferenceState()
        }
    }

    internal func callError(_ call: Call!, error: CallError, message: String) {
        NSLog("\(logtag) call error: \(error.stringValue), \(message)")
        Alert.show("Error", "\(message.isEmpty ? error.stringValue : message)")
        if let call {
            updateCallState(call)
            removeCall(call)
        }
    }
    
    internal func callConnectionLost(_ call: Call!) {
        NSLog("\(logtag) call connection lost")
        updateCallState(call)
        updateConferenceState()
    }

    internal func call(_ call: Call!, inConference: Bool) {
        NSLog("\(logtag) call \(call?.identifier ?? ""), in conference: \(inConference)")
        updateConferenceState()
    }

    internal func callMuted(_ call: Call!) {
        NSLog("\(logtag) call \(call.isMuted ? "" : "un")muted")
        for stored in calls {
            if call == stored.call {
                stored.mute = call.isMuted
                break
            }
        }
    }

    internal func callUserActionRequired(_ call: Call!, pendingEvent: CallPendingEvent, requiredAction: CallUserAction) {
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
                        call?.accept()
                    }
                    LocationAccessProvider.instance.requestAuthorization(deferredAction: action)
                }
            } else if status == .restricted || status == .denied {
                call.accept() // force SDK to fail on error
            }
        }
    }

    //MARK: registration delegate here
    internal func registered() {
        updateRegistrationState()
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
    }

}


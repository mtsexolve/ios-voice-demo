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
    }

    private let logtag = "CallClientWrapper:"

    private init() {
        let config = ExolveVoiceSDK.Configuration.default()
        config?.logConfiguration.logLevel = .LL_Debug
        config?.enableSipTrace = true
        config?.callKitConfiguration = CallKitConfiguration.default()
        config?.callKitConfiguration.notifyInForeground = true
        config?.callKitConfiguration.contactSearchHandler = {callNumber, callback in
            guard let callNumber else { return }
            guard let callback else { return }
            let result = findContactName(callNumber)
                ?? formatCallNumber(callNumber, "+X (XXX) XXX-XXXX")
            callback(result)
        }

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

        let prefs = UserDefaults.standard
        login = prefs.string(forKey: UserKey.Login) ?? ""
        password = prefs.string(forKey: UserKey.Password) ?? ""
        lastCall = prefs.string(forKey: UserKey.LastCall) ?? ""

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
                    callClient.placeCall(number)
                }
            }
            break
        case AVAudioSession.RecordPermission.granted:
            NSLog("\(logtag) call to \"\(number)\"")
                callClient.placeCall(number)
            break
        default:
            NSLog("\(logtag) no record permission")
            break
        }
    }

    private func setCallState(_ call: Call) {
        for stored in calls {
            if call == stored.call {
                stored.state = call.state
            }
        }

        let info = ["call": call, "state": call.state] as [String : Any]
        NotificationCenter.default.post(name: .call, object: nil, userInfo: info)
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

    func callTransfer(call: Call!, targetId: String) {
        NSLog("\(logtag) call transfer to targetId = \(targetId)")
        for stored in calls {
            if call == stored.call {
                call.transfer(targetId)
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

    //MARK: calls delegate here
    internal func callNew(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call new")
            calls.append(CallData(call))
            setCallState(call)
        }
    }

    internal func callConnected(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call connected")
            setCallState(call)
        }
    }

    internal func callHold(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call hold")
            setCallState(call)
            updateConferenceState()
        }
    }

    internal func callDisconnected(_ call: Call!) {
        if let call {
            NSLog("\(logtag) call disconnected")
            setCallState(call)
            removeCall(call)
            updateConferenceState()
        }
    }

    internal func callError(_ call: Call!, error: CallError, message: String) {
        NSLog("\(logtag) call error: \(error.stringValue), \(message)")
        Alert.show("Call error", message == "" ? error.stringValue : message)
        if let call {
            setCallState(call)
            removeCall(call)
        }
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
    
    private func updateState(_ error:RegistrationError? = nil,_ errorMessage: String? = nil) {
        registrationState = callClient.registrationState()
        if let error = error, let errorMessage = errorMessage {
            NSLog("\(logtag) error: \(error.stringValue), \(errorMessage)")
            if error == .RE_BadCredentials {
                Alert.show("Error", "Bad credentials: \n\(errorMessage)")
            }
        } else {
            NSLog("\(logtag) \(registrationState.stringValue)")
        }
    }

    //MARK: registration delegate here
    internal func registered() {
        updateState()
    }

    internal func registering() {
        updateState()
    }

    internal func notRegistered() {
        updateState()
    }

    internal func offline() {
        updateState()
    }

    internal func noConnection() {
        updateState()
    }

    internal func registrationError(_ error: RegistrationError, message: String) {
        updateState(error, message)
    }

}


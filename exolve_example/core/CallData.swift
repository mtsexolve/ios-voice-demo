import Foundation

final class CallData: ObservableObject {
    var call: Call!
    var callId: String { get {return call.identifier} }
    var number: String { get {return call.formattedNumber} }
    @Published var state: CallState
    @Published var mute: Bool
    @Published var locationAccessRequired: Bool

    init(_ call: Call ) {
        self.call = call
        state = call.state
        mute = call.isMuted
        locationAccessRequired = false
    }

}

extension CallData {
    var isNewIncoming: Bool {
        return call.state == .CS_New && call.direction == .CD_Incoming
    }
}

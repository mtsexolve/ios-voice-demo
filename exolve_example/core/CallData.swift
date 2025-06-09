import Foundation

final class CallData: ObservableObject {
    var call: Call!
    var callId: String { get {return call.identifier} }
    var number: String { get {return call.formattedNumber} }
    var extraContext: String { get {return call.extraContext ?? ""} }
    var qualityRating: Float = 5.0
    @Published var state: CallState
    @Published var mute: Bool
    @Published var locationAccessRequired: Bool = false
    @Published var duration: UInt = 0

    init(_ call: Call ) {
        self.call = call
        state = call.state
        mute = call.isMuted
    }

}

extension CallData {
    var isNewIncoming: Bool {
        return call.state == .CS_New && call.direction == .CD_Incoming
    }

    var isAlive: Bool {
        return call.state == .CS_Connected || call.state == .CS_OnHold || call.state == .CS_LostConnection
    }

    func updateStatistics() {
        if isAlive {
            if state == CallState.CS_Connected {
                if let statistics = call.statistics {
                    qualityRating = statistics.currentRating
                }
            }
            duration = call.duration
        }
    }
}

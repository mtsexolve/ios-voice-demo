import Foundation

final class CallData: ObservableObject {
    var call: Call!
    var callId: String { get {return call.identifier} }
    var number: String { get {return call.number} }
    @Published var state: CallState
    @Published var mute: Bool

    init(_ call: Call ) {
        self.call = call
        state = call.state
        mute = call.isMuted
    }
}

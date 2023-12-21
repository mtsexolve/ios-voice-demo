import SwiftUI

struct RootView: View {
    @State private var showCalls = false

    @ObservedObject private var client = CallClientWrapper.instance

    @State private var activeCall: CallData?
    @State private var opacity = 0.0

    var body: some View {
        return Group {
            ZStack {
                VStack {
                    HStack {
                        Image(systemName: Images.InfoCircle)
                            .padding(.leading)
                        Text("\(Strings.RegistrationState) \(client.registrationState.stringValue)")
                        Spacer()
                    }

                    if !client.calls.isEmpty && !showCalls {
                        HStack {
                            Spacer()
                            Image(systemName: Images.Back)
                            Text(Strings.BackToCall)
                            Spacer()
                        }
                        .onTapGesture { showCallsView() }
                    }

                    ZStack {
                        AccountCallTabView()
                        if showCalls {
                            if activeCall != nil {
                                CallsView(activeCall: $activeCall)
                                    .transition(.move(edge: .bottom))
                            }
                        }
                    }
                }
            } // ZStack
        }
        .onReceive(NotificationCenter.default.publisher(for: .call), perform: { (output) in
            guard let state = output.userInfo?["state"] as? CallState else {
                assertionFailure("missed call state info")
                return
            }

            guard let call = output.userInfo?["call"] as? Call else {
                assertionFailure("missed call info")
                return
            }

            switch(state) {
            case .CS_New:
                showCallsView()
                setActiveCall(call)
                break
            case .CS_Terminated, .CS_Error:
                let arr = client.getAliveCalls()
                if !arr.isEmpty {
                    if let callId = activeCall?.call.identifier {
                        if callId == call.identifier {
                            activeCall = arr[0]
                        }
                    }
                } else {
                    hideCallsView()
                    activeCall = nil
                }
                break;
            default:
                break
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .setActiveCall), perform: { (output) in
            guard let call = output.userInfo?["call"] as? Call else {
                assertionFailure("missed call info")
                return
            }

            setActiveCall(call)
        })
        .onReceive(NotificationCenter.default.publisher(for: .showDialer), perform: { (output) in
            hideCallsView()
        })
        .onAppear(perform: {
            if let activeCall = client.getAliveCalls().first?.call {
                setActiveCall(activeCall)
                showCalls = true;
            }
        })
    }

    func showCallsView() {
        toggleCallsView(true)
    }

    func hideCallsView() {
        toggleCallsView(false)
    }

    func toggleCallsView(_ value: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCalls = value
        }
    }

    func setActiveCall(_ call: Call) {
        if let data = client.calls.first(where: {$0.call.identifier == call.identifier}) {
            activeCall = data
        }
    }

}


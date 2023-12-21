import SwiftUI
import ContactsUI

struct CallsView: View {
    @State private var showDialpad: Bool = false
    
    @Binding var activeCall: CallData?

    @ObservedObject private var client = CallClientWrapper.instance

    private let logtag = "CallsView:"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .contentShape(Rectangle())

            VStack {
                if let activeCall {
                    if client.conferenceActive {
                        ConferenceView()
                    }

                    ScrollView {
                        ForEach(client.calls, id: \.callId) { callData in
                            if !callData.call.inConference {
                                CallItem(data: callData, activeCall: activeCall)
                                    .onDrag {
                                        NSLog("\(logtag) drag item \(callData.number) id \(callData.callId)")
                                        return NSItemProvider(object: callData.callId as NSString)
                                    }
                            }
                        }
                    }
                    .layoutPriority(1)

                    CallsKeyboard(activeCall: activeCall)
                }

            } // vstack
            
            if (showDialpad) {
                DtmfView (activeCall: $activeCall)
            }
        } // zstack
        .onReceive(NotificationCenter.default.publisher(for: .showDtmfKeypad), perform: { (output) in
            self.showDialpad = true
        })
        .onReceive(NotificationCenter.default.publisher(for: .hideDtmfKeyad), perform: { (output) in
            self.showDialpad = false
        })
    }

}

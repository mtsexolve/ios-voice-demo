import SwiftUI
import ContactsUI

struct CallsView: View {
    @State private var showDialpad: Bool = false
    @State private var onDropData: OnDropData? = nil
    @Binding var activeCall: CallData?
    @ObservedObject private var client = CallClientWrapper.instance

    private let logtag = "CallsView:"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .contentShape(Rectangle())

            Group {
                VStack {
                    if let activeCall {
                        if client.conferenceActive {
                            ConferenceView()
                        }

                        ScrollView {
                            ForEach(Array(client.calls.enumerated()), id: \.1.callId) { index , callData in
                                if !callData.call.inConference {
                                    CallItem(data: callData, activeCall: activeCall, index: index, onDropData: $onDropData)
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
            } // group
            if let data = $onDropData.wrappedValue {
                OnDropActionSelectorView(data: data, closeCallback: { onDropData = nil })
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

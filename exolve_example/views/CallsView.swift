import SwiftUI
import ContactsUI

struct CallsView: View {
    @State private var showDtmfDialer: Bool = false
    @State private var showTransferDialer: Bool = false
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
                if (showDtmfDialer) {
                    DtmfView (activeCall: $activeCall)
                } else if (showTransferDialer) {
                    DialerView (activeCall: $activeCall, isTransferDialer: true)
                } else {
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
                }
            } // group
            if let data = $onDropData.wrappedValue {
                OnDropActionSelectorView(data: data, closeCallback: { onDropData = nil })
            }
        } // zstack
        .onReceive(NotificationCenter.default.publisher(for: .showDtmfKeypad), perform: { (output) in
            self.showDtmfDialer = true
        })
        .onReceive(NotificationCenter.default.publisher(for: .hideDtmfKeyad), perform: { (output) in
            self.showDtmfDialer = false
        })
        .onReceive(NotificationCenter.default.publisher(for: .showTransferKeypad), perform: { (output) in
            self.showTransferDialer = true
        })
        .onReceive(NotificationCenter.default.publisher(for: .hideTransferKeypad), perform: { (output) in
            self.showTransferDialer = false
        })
    }

}

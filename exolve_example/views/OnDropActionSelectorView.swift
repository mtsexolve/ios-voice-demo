import SwiftUI

struct OnDropData {
    let first: CallData
    let second: CallData
}

struct OnDropActionSelectorView: View {

    var data: OnDropData
    var closeCallback: () -> Void

    @ObservedObject private var client = CallClientWrapper.instance

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black)
                .opacity(0.1)
                .contentShape(Rectangle())
                .onTapGesture { closeCallback() }
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    VStack {
                        HStack {
                            Image(systemName:"person.circle")
                            Text(data.first.number)
                                .font(.custom("MTSWide-Regular", size: 16))
                            Spacer()
                            Text(data.second.number)
                                .font(.custom("MTSWide-Regular", size: 16))
                            Image(systemName:"person.circle")
                        }
                        Divider()
                        Group {
                            Button (action: doConference) {
                                VStack {
                                    Text(Strings.CallsActionConference)
                                        .font(font_reg)
                                    Text(Strings.CallsActionConferenceHint)
                                }
                            }
                            Button (action: doTransfer) {
                                VStack {
                                    Text(Strings.CallsActionTransfer)
                                        .font(font_reg)
                                    Text(Strings.CallsActionTransferHint)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(UIColor.link), lineWidth: 0.5)
                        )
                    }
                    .padding(10)
                    .background(Rectangle()
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    )
                    Spacer()
                }
                Spacer()
            }
            Spacer()
        }
        .onReceive(client.$calls) { calls in
            if calls.filter({$0.call.identifier == data.first.call.identifier
                || $0.call.identifier == data.second.call.identifier}).count < 2 {
                closeCallback()
            }
        }
    }

    private func doConference() {
        data.first.call.createConference(data.second.callId)
        closeCallback()
    }

    private func doTransfer() {
        client.callTransfer(call: data.second.call, toCall: data.first.call.identifier)
        closeCallback()
    }
}

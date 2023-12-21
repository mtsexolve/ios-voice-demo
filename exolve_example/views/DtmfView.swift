import SwiftUI

struct DtmfView: View {
    @Binding var activeCall: CallData?
    @State var sequence = ""

    let close = Image(systemName: Images.Close)

    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.white)
            VStack {
                TextField("", text: $sequence)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .disabled(true)
                    .foregroundColor(.black)

                HStack {
                    DialerButton(action: {onNumber("1")}, color: grey, label: Text("1"))
                    DialerButton(action: {onNumber("2")}, color: grey, label: Text("2"))
                    DialerButton(action: {onNumber("3")}, color: grey, label: Text("3"))
                }
                HStack {
                    DialerButton(action: {onNumber("4")}, color: grey, label: Text("4"))
                    DialerButton(action: {onNumber("5")}, color: grey, label: Text("5"))
                    DialerButton(action: {onNumber("6")}, color: grey, label: Text("6"))
                }
                HStack {
                    DialerButton(action: {onNumber("7")}, color: grey, label: Text("7"))
                    DialerButton(action: {onNumber("8")}, color: grey, label: Text("8"))
                    DialerButton(action: {onNumber("9")}, color: grey, label: Text("9"))
                }
                HStack {
                    DialerButton(action: {onNumber("*")}, color: grey, label: Text(Strings.SmallAsterisk))
                    DialerButton(action: {onNumber("0")}, color: grey, label: Text("0"))
                    DialerButton(action: {onNumber("#")}, color: grey, label: Text("#"))
                }
                HStack {
                    DialerButton(action: onHide, color: nil, label: close)
                }
            }
            .font(font_mts).foregroundColor(.black)
        }
    }

    func onNumber(_ char: String) {
        self.sequence += char
        if let activeCall {
            activeCall.call.sendDtmf(char);
        }
    }

    func onHide() {
        NotificationCenter.default.post(name: .hideDtmfKeyad, object: nil, userInfo: nil)
    }

}


import SwiftUI

struct DialerView: View {
    @State var callNumber = CallClientWrapper.instance.lastCall

    var body: some View {
        VStack {
            TextField("", text: $callNumber)
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
                Circle()
                    .fill(Color.clear)
                    .frame(width: 77, height: 77, alignment: .center)
                DialerButton(action: onCall, color: green, label: Image(systemName: Images.CallResume))
                    .foregroundColor(.white)
                DialerButton(action: onDel, color: nil, label: Image(systemName: Images.Backspace))
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1)
                    .onEnded { _ in callNumber = "" })
            }
        }
        .font(font_mts).foregroundColor(.black)
    }

    func onNumber(_ char: String) {
        callNumber += char
    }

    func onDel() {
        if !callNumber.isEmpty {
            callNumber.removeLast()
        }
    }

    func onCall() {
        CallClientWrapper.instance.callToNumber(number: callNumber)
    }

}

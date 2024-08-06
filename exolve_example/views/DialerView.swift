import SwiftUI

struct DialerView: View {
    @State var callNumber = CallClientWrapper.instance.lastCall
    private let contactPicker = ContactPickerView()

    var body: some View {
        VStack {
            TextField("", text: $callNumber)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .disabled(true)
                .foregroundColor(.black)
                .minimumScaleFactor(0.7)
            HStack {
                DialerButton(action: {onNumber("1")}, color: grey, label: Text("1"))
                    .accessibilityIdentifier("DialerButton1")
                DialerButton(action: {onNumber("2")}, color: grey, label: Text("2"))
                    .accessibilityIdentifier("DialerButton2")
                DialerButton(action: {onNumber("3")}, color: grey, label: Text("3"))
                    .accessibilityIdentifier("DialerButton3")
            }
            HStack {
                DialerButton(action: {onNumber("4")}, color: grey, label: Text("4"))
                    .accessibilityIdentifier("DialerButton4")
                DialerButton(action: {onNumber("5")}, color: grey, label: Text("5"))
                    .accessibilityIdentifier("DialerButton5")
                DialerButton(action: {onNumber("6")}, color: grey, label: Text("6"))
                    .accessibilityIdentifier("DialerButton6")
            }
            HStack {
                DialerButton(action: {onNumber("7")}, color: grey, label: Text("7"))
                    .accessibilityIdentifier("DialerButton7")
                DialerButton(action: {onNumber("8")}, color: grey, label: Text("8"))
                    .accessibilityIdentifier("DialerButton8")
                DialerButton(action: {onNumber("9")}, color: grey, label: Text("9"))
                    .accessibilityIdentifier("DialerButton9")
            }
            HStack {
                DialerButton(action: {onNumber("*")}, color: grey, label: Text(Strings.SmallAsterisk))
                    .accessibilityIdentifier("DialerButtonAsterisk")
                DialerButton(action: {onNumber("0")}, color: grey, label: Text("0"))
                    .accessibilityIdentifier("DialerButton0")
                DialerButton(action: {onNumber("#")}, color: grey, label: Text("#"))
                    .accessibilityIdentifier("DialerButton#")
            }
            HStack {
                let contacts = Image(systemName: Images.Contacts)
                    .font(.custom("", size: 36))
                DialerButton(action: onContacts, color: nil, label: contacts)
                    .accessibilityIdentifier("DialerButtonContacts")
                DialerButton(action: onCall, color: green, label: Image(systemName: Images.CallResume))
                    .foregroundColor(.white)
                    .accessibilityIdentifier("DialerButtonCall")
                DialerButton(action: onDel, color: nil, label: Image(systemName: Images.Backspace))
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1)
                    .onEnded { _ in callNumber = "" })
                    .accessibilityIdentifier("DialerBackspaceButton")
            }
        }
        .font(font_mts).foregroundColor(.black)
    }

    private func onNumber(_ char: String) {
        callNumber += char
    }

    private func onDel() {
        if !callNumber.isEmpty {
            callNumber.removeLast()
        }
    }

    private func onCall() {
        CallClientWrapper.instance.callToNumber(number: callNumber)
    }

    private func onContacts() {
        contactPicker.selectPhoneNumber = { (selectedNumber : String?) in
            if let number = selectedNumber {
                callNumber = number
            }
        }
        contactPicker.pickContact()
    }

}

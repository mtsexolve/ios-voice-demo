import SwiftUI

struct AccountView: View {
    @State private var login: String
    @State private var password: String
    @State private var location = CallClientWrapper.instance.locationServiceEnabled

    @ObservedObject private var client = CallClientWrapper.instance

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onTapGesture { resignFirstResponder() }

            VStack {
                AccountTextField(value: $login, hint: Strings.EnterLogin)
                AccountTextField(value: $password, hint: Strings.EnterPassword)

                Button(action: onToggleActivate) {
                    Text(client.registrationState == .RS_NotRegistered ? Strings.Activate : Strings.Deactivate)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .disabled(true)
                        .font(Font.custom("MTSWide-Regular", size: 18))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 50)
                .background(Rectangle()
                    .cornerRadius(10)
                    .foregroundColor(red)
                )

                Spacer()
                if !client.pushToken.isEmpty {
                    VStack {
                        Text(Strings.PushTokenDescription)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.subheadline)
                        Text(client.pushToken)
                            .font(Font.custom("MTSWide-Regular", size: 16))
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 0.25)
                            )
                            .onTapGesture { onTapToCopy() }
                    }
                }
                HStack {
                    Toggle(isOn: $location) {
                        Text(Strings.CallLocation)
                    }
                    .onChange(of: location, perform: { value in client.enableLocationService(value) })
                    .foregroundColor(Color(UIColor.link))
                    .toggleStyle(.check)
                    Spacer()
                }
                HStack {
                    Text(Bundle.main.bundleIdentifier! + "\n" + client.versionDescription)
                        .font(Font.custom("MTSWide-Regular", size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                    Button(Strings.SendLogs) { SharingProvider.instance.share() }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
    }

    init() {
        login = CallClientWrapper.instance.login
        password = CallClientWrapper.instance.password
    }

    func onToggleActivate() {
        resignFirstResponder()

        if client.registrationState == .RS_NotRegistered {
            client.register(login, password)
        } else {
            client.unregister()
        }
    }

    func onTapToCopy() {
        UIPasteboard.general.setValue(client.pushToken, forPasteboardType: "public.plain-text")
        Alert.show("", Strings.PushTokenCopyConfirmation)
    }

}

struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: ToggleStyle.Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.circle" : "circle")
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckToggleStyle {
    static var check: CheckToggleStyle { .init() }
}

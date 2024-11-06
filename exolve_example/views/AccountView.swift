import SwiftUI
import Combine

struct AccountView: View {
    @State private var login: String
    @State private var password: String
    @ObservedObject private var client = CallClientWrapper.instance
    @EnvironmentObject var sceneDelegate: SceneDelegate

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onTapGesture { resignFirstResponder() }

            VStack {
                Group {
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
                }
                .padding(.horizontal)
            }
        }
        .onReceive(sceneDelegate.$authorizationString) { newValue in
            if newValue.isEmpty {
                return
            }
            if let dIndex = newValue.firstIndex(of: "&") {
                login = String(newValue[..<dIndex])
                password = String(newValue[newValue.index(after: dIndex)...])
                
                if client.registrationState != .RS_NotRegistered {
                    client.unregister()
                    var sub : AnyCancellable?
                    sub = client.$registrationState
                                   .sink { newValue in
                                       if newValue == RegistrationState.RS_NotRegistered {
                                           client.register(login, password)
                                           if let _ = sub {
                                               sub = nil
                                           }
                                       }
                                   }
                } else {
                    client.register(login, password)
                }
            }
         }
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

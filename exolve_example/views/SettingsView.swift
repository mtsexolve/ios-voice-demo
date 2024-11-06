
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var client = CallClientWrapper.instance
    @State private var useLocation = Storage.location
    @State private var useSipTraces = Storage.sipTraces
    @State private var logLevel = Storage.logLevel
    @State private var useEncryption = Storage.encryption
    @State private var environment = Storage.environment
    @State var needRestart = false

    enum AlertType {
        case ClearLogs
        case RestartApp
    }

    @State private var whichAlertShouldShow: AlertType?
    @State private var shouldShowAlert = false


    static private let logLevels: [LogLevel] = [
        LogLevel.LL_Trace, LogLevel.LL_Debug, LogLevel.LL_Info, LogLevel.LL_Warning, LogLevel.LL_Error
    ]
    static private let logLevelsDescription: [String] = ["Trace", "Debug", "Info", "Warning", "Error"]

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Toggle(isOn: $useLocation) {
                    Text(Strings.SettingsCallLocation)
                }
                .onChange(of: useLocation, perform: { value in client.enableLocationService(value) })
                .toggleStyle(.check)
                .padding(.bottom, 1)

                Toggle(isOn: $useSipTraces) {
                    Text(Strings.SettingsSipTraces)
                }
                .onChange(of: useSipTraces, perform: { value in
                    Storage.sipTraces = value
                    needRestart = true
                })
                .toggleStyle(.check)

                HStack {
                    Text(Strings.SettingsLogLevel)
                    Menu(SettingsView.logLevelsDescription[logLevel.rawValue]) {
                        ForEach(SettingsView.logLevels, id: \.self) { level in
                            Button(SettingsView.logLevelsDescription[level.rawValue], action: {
                                logLevel = level
                                Storage.logLevel = level
                                needRestart = true
                            })
                        }
                    }
                    .foregroundColor(Color(UIColor.label))
                }
                .padding(.bottom, 4)

                Toggle(isOn: $useEncryption) {
                    Text(Strings.SettingsEncryption)
                }
                .onChange(of: useEncryption, perform: { value in
                    Storage.encryption = value
                    needRestart = true
                })
                .toggleStyle(.check)

                HStack {
                    Text(Strings.SettingsEnvironment)
                    Menu(environment) {
                        ForEach(client.getAvailableEnvironments(), id: \.self) { env in
                            Button(env, action: {
                                environment = env
                                Storage.environment = env
                                needRestart = true
                            })
                        }
                    }
                    .foregroundColor(Color(UIColor.label))
                }


                Spacer()

                if (needRestart) {
                    VStack {
                        Button(action: {
                            shouldShowAlert = true;
                            whichAlertShouldShow = .RestartApp
                        }) {
                            Text(Strings.SettingsRestart)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .disabled(true)
                                .font(Font.custom("MTSWide-Regular", size: 18))
                                .foregroundColor(.white)
                        }
                        .frame(width: 260, height: 50)
                        .background(Rectangle()
                            .cornerRadius(10)
                            .foregroundColor(red)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .alert(isPresented: $shouldShowAlert, content: {
                presentAlert()
            })

            HStack {
                Image(systemName: Images.InfoCircle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(height: 14)
                    .padding(.leading, 2)
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
                Text("\(Bundle.main.bundleIdentifier!)\nv\(version), \(client.versionDescription)")
                    .font(Font.custom("MTSWide-Regular", size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {}) {
                    Text(Strings.SendLogs)
                        .onTapGesture { SharingProvider.instance.share() }
                        .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 20) {
                            shouldShowAlert = true
                            whichAlertShouldShow = .ClearLogs
                        }
                }
                .padding(.trailing)

            }
            .padding(.top, 10)
        }

    }

    func onClearLogs() {
        SharingProvider.instance.removeOldFiles()
    }

    func presentAlert() -> SwiftUI.Alert {
        if whichAlertShouldShow == .ClearLogs {
            return SwiftUI.Alert(title: Text(Strings.ClearLogsTitle), message: Text(Strings.ClearLogsMessage),
                primaryButton: SwiftUI.Alert.Button.destructive(Text(Strings.ClearLogsConfirm), action: onClearLogs),
                secondaryButton: SwiftUI.Alert.Button.cancel(Text(Strings.ClearLogsCancel), action: { shouldShowAlert = false }))
        }

        return SwiftUI.Alert(title: Text(Strings.SettingsRestart), message: Text(Strings.SettingsRestartWarning),
            primaryButton: SwiftUI.Alert.Button.destructive(Text(Strings.SettingsProceed), action: { exit(0) }),
            secondaryButton: SwiftUI.Alert.Button.cancel(Text(Strings.SettingsCancel), action: { shouldShowAlert = false }))
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

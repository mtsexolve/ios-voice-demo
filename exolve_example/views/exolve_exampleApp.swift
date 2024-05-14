import SwiftUI
import Contacts
import AVFAudio

@main
struct exolve_exampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logtag = "AppDelegate:"

    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Task {
            do {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
            } catch {
                NSLog("\(logtag) request notification authorization error")
            }

            do {
                try await CNContactStore().requestAccess(for: .contacts)
            } catch {
                NSLog("\(logtag) request access to contacts error")
            }

            AVAudioSession.sharedInstance().requestRecordPermission { [self] (granted: Bool) in
                NSLog("\(logtag) record permission \(granted ? "" : "not ")granted")
            }
        }

        return true
    }

}


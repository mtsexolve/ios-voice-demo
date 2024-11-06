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

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    var window: UIWindow?
    @Published var authorizationString: String = ""
    private let logtag = "SceneDelegate:"

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        NSLog("\(logtag) Scene will connect to session")
        if let url = connectionOptions.urlContexts.first?.url {
            putAuthorizationString(url:url)
        }
        else if let url = connectionOptions.userActivities.first?.webpageURL {
            putAuthorizationString(url:url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            putAuthorizationString(url:url)
        }
    }
    
    private func putAuthorizationString(url : URL) {
        NSLog("\(logtag) Incoming URL:\(url)")
        authorizationString = url.host ?? "" + url.path
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
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
    

    func application(
      _ application: UIApplication,
      configurationForConnecting connectingSceneSession: UISceneSession,
      options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
      let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
      sceneConfig.delegateClass = SceneDelegate.self
      return sceneConfig
    }

}


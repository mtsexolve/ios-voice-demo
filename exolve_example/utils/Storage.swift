
import Foundation

class Storage {
    private static let prefs = UserDefaults.standard

    private struct Keys {
        static let Login = "login"
        static let Password = "password"
        static let LastCall = "last_call"
        static let Location = "location"
        static let SipTraces = "sip_traces"
        static let LogLevel = "log_level"
        static let Encryption = "encryption"
        static let Environment = "environment"
    }

    static var login: String {
        get { prefs.string(forKey: Keys.Login) ?? "" }
        set { prefs.set(newValue, forKey: Keys.Login) }
    }

    static var password: String {
        get { prefs.string(forKey: Keys.Password) ?? "" }
        set { prefs.set(newValue, forKey: Keys.Password) }
    }

    static var lastCall: String {
        get { prefs.string(forKey: Keys.LastCall) ?? "" }
        set { prefs.set(newValue, forKey: Keys.LastCall) }
    }

    static var location: Bool {
        get { prefs.object(forKey: Keys.Location) as? Bool ?? true }
        set { prefs.set(newValue, forKey: Keys.Location) }
    }

    static var sipTraces: Bool {
        get { prefs.object(forKey: Keys.SipTraces) as? Bool ?? true }
        set { prefs.set(newValue, forKey: Keys.SipTraces) }
    }

    static var logLevel: LogLevel {
        get { LogLevel(rawValue: prefs.integer(forKey: Keys.LogLevel)) ?? .LL_Debug }
        set { prefs.set(newValue.rawValue, forKey: Keys.LogLevel) }
    }

    static var encryption: Bool {
        get { prefs.bool(forKey: Keys.Encryption) }
        set { prefs.set(newValue, forKey: Keys.Encryption) }
    }

    static var environment: String {
        get { prefs.string(forKey: Keys.Environment) ?? Strings.Default }
        set { prefs.set(newValue, forKey: Keys.Environment) }
    }

    static var callIntent: String?
}

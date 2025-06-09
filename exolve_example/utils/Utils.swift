import SwiftUI
import Contacts
import ExolveVoiceSDK

extension Notification.Name {

    static var call: Notification.Name {
        return .init(rawValue: "call")
    }

    static var setActiveCall: Notification.Name {
        return .init(rawValue: "setActiveCall")
    }

    static var showDialer: Notification.Name {
        return .init(rawValue: "showDialer")
    }
    
    static var showDtmfKeypad: Notification.Name {
        return .init(rawValue: "showDtmfKeyad")
    }
    
    static var hideDtmfKeyad: Notification.Name {
        return .init(rawValue: "hideDtmfKeyad")
    }

    static var showTransferKeypad: Notification.Name {
        return .init(rawValue: "showTransferKeypad")
    }
    
    static var hideTransferKeypad: Notification.Name {
        return .init(rawValue: "hideTransferKeypad")
    }
    
    static var voipPushToken: Notification.Name {
        return .init(rawValue: "deviceVoipPushTokenUpdatedEvent")
    }

}

extension RegistrationState {
    var stringValue: String {
        return ["not registered", 
                "registering",
                "registered",
                "offline",
                "no connection",
                "error"][rawValue]
    }
}

extension CallState {
    var stringValue: String {
        return ["new call",
                "connected",
                "on hold",
                "terminated",
                "error",
                "lost connection"][rawValue]
    }
}

let font_mts = Font.custom("MTSWide-Regular", size: 36)
let font_reg = Font.custom("MTSWide-Regular", size: 20)

let grey = Color("GrayButtonBg")
let green = Color("GreenButtonBg")
let red = Color("RedButtonBg")

func resignFirstResponder() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

func getTopViewController() -> UIViewController? {
    var vc = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController
    while let presentedViewController = vc?.presentedViewController {
        vc = presentedViewController
    }
    return vc
}

let UTF8PlainText = "public.utf8-plain-text"

func formatCallNumber(_ callNumber: String, _ mask: String) -> String {
    let number = callNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    var result = ""
    var index = number.startIndex
    var maskIndex = mask.startIndex

    while index < number.endIndex && maskIndex < mask.endIndex {
        let maskChar = mask[maskIndex]
        let numberChar = number[index]

        if maskChar == "X" {
            result.append(numberChar)
            index = number.index(after: index)
        } else {
            result.append(maskChar)
        }

        maskIndex = mask.index(after: maskIndex)
    }

    return result
}

func findContactName(_ callNumber: String) -> String? {
    let fetchP = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: callNumber))
    let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
    do {
        let contact = try CNContactStore().unifiedContacts(matching: fetchP, keysToFetch: keys).first
        if let contact {
            let name = CNContactFormatter.string(from: contact, style: .fullName)
            return name
        }
    } catch {}
    return nil
}

func contactSearchHandler(_ callNumber: String, _ context: String?, _ callback: (String) -> Void) -> Void  {
    let format = "+X (XXX) XXX-XXXX"
    if !(context ?? "").isEmpty {
        callback("Call with context: \(context!)")
    } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
        callback(findContactName(callNumber) ?? formatCallNumber(callNumber, format))
    } else {
        callback(formatCallNumber(callNumber, format))
    }
}

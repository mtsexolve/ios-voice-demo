import ContactsUI
import Foundation

class ContactPickerView: NSObject, CNContactPickerDelegate{
    var selectPhoneNumber: ((String) -> Void)?

    private let logtag = "ContactPickerView:"

    func pickContact() {
        NSLog("\(logtag) pick contact")
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
        contactPicker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey]
        getTopViewController()?.present(contactPicker, animated: true, completion: nil)
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        let str = (contactProperty.value as? CNPhoneNumber)?.stringValue
        if let str {
            selectPhoneNumber?(str.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression))
        }
        NSLog("\(logtag) selected \(str ?? "nothing")")
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        if let firstPhoneNumber = contact.phoneNumbers.first?.value {
            selectPhoneNumber?(firstPhoneNumber.stringValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression))
        }
        NSLog("\(logtag) selected call = \(contact.phoneNumbers.first?.value.stringValue ?? "null")")
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        selectPhoneNumber = nil
    }

}

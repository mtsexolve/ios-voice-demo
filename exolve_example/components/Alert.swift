import SwiftUI

class Alert {
    private static var activeAlert: UIViewController? = nil

    static func show(_ title: String, _ message: String) {
        execOnApplicationActive { [title, message] in
            DispatchQueue.main.async {
                if let vc = getTopViewController() {
                    if let controller = activeAlert {
                        controller.dismiss(animated: true, completion: nil)
                        controller.removeFromParent()
                    }
                    activeAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    vc.present(activeAlert!, animated: true, completion: nil)
                    let hide = { (_: Timer) in
                        if let controller = activeAlert {
                            controller.dismiss(animated: true, completion: nil)
                            controller.removeFromParent()
                            activeAlert = nil
                        }
                    }
                    Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: hide)
                }
            }
        }
    }
}

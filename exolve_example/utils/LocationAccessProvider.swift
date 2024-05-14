import Foundation

class LocationAccessProvider: NSObject, CLLocationManagerDelegate {

    static let instance = LocationAccessProvider()

    private let locationManager = CLLocationManager()
    private var deferredAction: (() -> Void)?
    private var observer: Any? = nil

    private let logtag = "LocationAccessProvider:"
    private let сategory = "location"

    override init() {
        super.init()
        locationManager.delegate = self
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public var authorizationStatus: CLAuthorizationStatus { return locationManager.authorizationStatus }

    public func requestAuthorization(deferredAction: @escaping () -> Void) {
        NSLog("\(logtag) requesting location access")
        self.deferredAction = deferredAction

        if UIApplication.shared.applicationState == .active {
            locationManager.requestAlwaysAuthorization()
            return
        }

        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                NSLog("LocationAccessProvider: app did become active, requesting authorization")
                if let observer = self?.observer {
                    NotificationCenter.default.removeObserver(observer)
                    self?.observer = nil
                }
                self?.locationManager.requestAlwaysAuthorization()
        }
    }

    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            NSLog("\(logtag) authorization not yet determined")
            return
        case .authorizedAlways, .authorizedWhenInUse:
            NSLog("\(logtag) authorization granted, now executing")
        default: // .denied, .restricted
            NSLog("\(logtag) authorization not granted")
        }

        NSLog("\(logtag) execute deferred action")
        deferredAction?()
        deferredAction = nil
    }

} // class

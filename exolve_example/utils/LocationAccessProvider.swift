import Foundation

class LocationAccessProvider: NSObject, CLLocationManagerDelegate {

    static let instance = LocationAccessProvider()

    private let locationManager = CLLocationManager()
    private var deferredAction: (() -> Void)?

    private let logtag = "LocationAccessProvider:"
    private let сategory = "location"

    override init() {
        super.init()
        locationManager.delegate = self
    }

    public var authorizationStatus: CLAuthorizationStatus { return locationManager.authorizationStatus }

    public func requestAuthorization(_ deferredAction: (() -> Void)? = nil) {
        NSLog("\(logtag) requesting location access")
        self.deferredAction = deferredAction
        execOnApplicationActive { [self] in
            locationManager.requestAlwaysAuthorization()
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

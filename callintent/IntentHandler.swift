import Intents

class IntentHandler: INExtension, INStartCallIntentHandling {

    override func handler(for intent: INIntent) -> Any {
        return self
    }

    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        let activity = NSUserActivity(activityType: NSStringFromClass(INStartCallIntent.self))
        let response = INStartCallIntentResponse(code: .continueInApp, userActivity: activity)
        completion(response)
    }

}

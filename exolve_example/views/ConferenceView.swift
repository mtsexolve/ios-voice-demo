import SwiftUI

struct ConferenceView: View {
    @ObservedObject private var client = CallClientWrapper.instance

    private let logtag = "ConferenceView:"

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(Array(client.calls.enumerated()), id: \.1.callId) { index , data in
                    if data.call.inConference {
                        ConferenceItem(data: data)
                            .accessibilityIdentifier("ConferenceItem\(index)")
                    }
                }
            }
        }
        .onDrop(of: [UTF8PlainText], isTargeted: nil) { providers, location in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: UTF8PlainText) { (item, error) in
                    if let item = item as? Data {
                        let callId = NSString(data: item, encoding: NSUTF8StringEncoding)! as String
                        NSLog("\(logtag) drop item id \(callId)")
                        for callData in client.calls {
                            if (callData.callId == callId) {
                                callData.call.addToConference()
                                break
                            }
                        }
                    }
                }
            }
            return true
        }

    }
}


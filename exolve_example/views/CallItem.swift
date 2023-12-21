import SwiftUI

struct CallItem: View {
    @ObservedObject var data: CallData
    @ObservedObject var activeCall: CallData

    private let client = CallClientWrapper.instance

    private let logtag = "CallItem:"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(getFillColor())
                .cornerRadius(10)

            HStack {
                if data.call.state == .CS_Connected || data.call.state == .CS_OnHold {
                    getCallIcon()
                }

                VStack {
                    HStack {
                        Text(data.number)
                            .font(font_reg)
                            .padding(.leading)

                        Spacer()

                        if (data.mute) {
                            Image(systemName: Images.CallMute)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)

                    HStack {
                        Spacer()

                        Button(action: onTerminate) {
                            HStack {
                                if data.call.state == .CS_New && data.call.direction == .CD_Incoming {
                                    Image(systemName: Images.CallReject)
                                        .foregroundColor(Color.red)
                                    Text(Strings.CallReject)
                                } else {
                                    Image(systemName: Images.CallTerminate)
                                        .foregroundColor(Color.red)
                                    Text(Strings.CallTerminate)
                                }
                            }
                        }

                        Button(action: onTap) {
                            HStack {
                                if data.call.state == .CS_New && data.call.direction == .CD_Incoming {
                                    Image(systemName: Images.CallAnswer)
                                        .foregroundColor(Color.green)
                                    Text(Strings.CallAnswer)
                                } else if data.call.state == .CS_Connected {
                                    Image(systemName: Images.CallHold)
                                        .foregroundColor(Color.green)
                                    Text(Strings.CallHold)
                                } else if data.call.state == .CS_OnHold {
                                    Image(systemName: Images.CallResume)
                                        .foregroundColor(Color.green)
                                    Text(Strings.CallResume)
                                }
                            }
                        }

                    }
                    .padding(.bottom, 5)

                } // vstack
                .padding(.trailing)
            }
        } // zstack
        .onTapGesture { onTap() }
        .onDrop(of: [UTF8PlainText], isTargeted: nil) { providers, location in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: UTF8PlainText) { (item, error) in
                    if let item = item as? Data {
                        let callId = NSString(data: item, encoding: NSUTF8StringEncoding)! as String
                        NSLog("\(logtag) drop item id \(callId)")
                        if data.call.identifier != callId {
                            data.call.createConference(callId)
                        }
                    }
                }
            }
            return true
        }
    }

    func onTap() {
        NotificationCenter.default.post(name: .setActiveCall, object: nil, userInfo: ["call": data.call as Any])
        if data.call.state == .CS_OnHold {
            NSLog("\(logtag) resume")
            data.call.resume()
        } else if data.call.state == .CS_Connected {
            NSLog("\(logtag) hold")
            data.call.hold()
        } else if data.call.state == .CS_New && data.call.direction == .CD_Incoming {
            NSLog("\(logtag) accept")
            data.call.accept()
        }
    }

    func onTerminate() {
        NSLog("\(logtag) terminate")
        data.call.terminate()
    }

    func getFillColor() -> Color {
        return activeCall.callId == data.callId ? Color("GrayButtonBg") : Color.white
    }

    func getCallIcon() -> AnyView {
        switch (data.call.state) {
        case .CS_Connected:
            return AnyView(Image(systemName: Images.CallActive)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.leading))
        case .CS_OnHold:
            return AnyView(Image(systemName: Images.Pause)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(width: 25, height: 25, alignment: .center)
                .padding(.leading))
        default:
            return AnyView(Circle()
                .fill(Color.clear)
                .frame(width: 77, height: 77, alignment: .center))
        }
    }
}

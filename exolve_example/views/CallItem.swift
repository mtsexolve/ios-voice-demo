import SwiftUI

struct CallItem: View {
    @ObservedObject var data: CallData
    @ObservedObject var activeCall: CallData
    var index: Int
    @Binding var onDropData: OnDropData?

    private let client = CallClientWrapper.instance

    private let logtag = "CallItem:"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(getFillColor())
                .cornerRadius(10)

            HStack {
                if data.isAlive {
                    getCallIcon()
                }

                VStack {
                    HStack {
                        Text(data.number)
                            .font(font_reg)
                            .padding(.leading, data.isAlive ? 0 : nil)

                        Spacer()

                        if (data.mute) {
                            Image(systemName: Images.CallMute)
                                .foregroundColor(.gray)
                        }
                        if data.call.state == .CS_Connected {
                            Circle().fill(getQulityRatingFillColor()).frame(width: 10, height: 10)
                                .accessibilityIdentifier("CallItemQualityRating\(index)_\(getQulityRatingFillColor().description)")
                        }
                    }
                    .padding(.vertical, 5)
                    
                    if !data.extraContext.isEmpty {
                        Text(data.extraContext)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, data.isAlive ? 0 : nil)
                            .padding(.vertical, 5)
                    }
                    
                    HStack {
                        if data.isAlive {
                            Text(formatDuration(data.duration))
                                .font(Font.custom("MTSWide-Regular", size: 14))
                                .foregroundColor(.gray)
                                .padding(.leading, 0)
                        }

                        Spacer()

                        Button(action: onTerminate) {
                            HStack {
                                if data.isNewIncoming {
                                    Image(systemName: Images.CallReject)
                                        .foregroundColor(Color.red)
                                    Text(Strings.CallReject)
                                } else {
                                    Image(systemName: Images.CallTerminate)
                                        .foregroundColor(Color.red)
                                    Text(Strings.CallTerminate)
                                }
                            }
                        }.accessibilityIdentifier("CallItemTerminate\(index)")

                        if !(data.locationAccessRequired && data.isNewIncoming) {
                            Button(action: onTap) {
                                HStack {
                                    if data.isNewIncoming {
                                        Image(systemName: Images.CallAnswer)
                                            .foregroundColor(Color.green)
                                            .accessibilityIdentifier("CallItemButtonStateNew\(index)")
                                        Text(Strings.CallAnswer)
                                    } else if data.call.state == .CS_Connected {
                                        Image(systemName: Images.CallHold)
                                            .foregroundColor(Color.green)
                                            .accessibilityIdentifier("CallItemButtonStateConnected\(index)")
                                        Text(Strings.CallHold)
                                    } else if data.call.state == .CS_OnHold {
                                        Image(systemName: Images.CallResume)
                                            .foregroundColor(Color.green)
                                            .accessibilityIdentifier("CallItemButtonStateOnHold\(index)")
                                        Text(Strings.CallResume)
                                    }
                                }
                            }.accessibilityIdentifier("CallItemButton\(index)")
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
                            if let secondCall = client.calls.first(where: {$0.call.identifier == callId}) {
                                onDropData = OnDropData(first: data, second: secondCall)
                            }
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
        } else if data.isNewIncoming {
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
    
    func getQulityRatingFillColor() -> Color {
        if data.qualityRating > 4.2 {
            return Color.green
        } else if data.qualityRating > 2.5 {
            return Color.yellow
        } else if data.qualityRating >= 0 {
            return Color.red
        } else {
            return Color(red: 0.5, green: 0.0, blue: 0.0)
        }
    }
    

    func getCallIcon() -> AnyView {
        switch (data.call.state) {
        case .CS_Connected:
            return AnyView(Image(systemName: Images.CallActive)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.leading)
                .accessibilityIdentifier("CallStatusConnected")
            )
        case .CS_OnHold:
            return AnyView(Image(systemName: Images.Pause)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(width: 25, height: 25, alignment: .center)
                .padding(.leading))
        case .CS_LostConnection:
            return AnyView(Image(systemName: Images.CallLostConnection)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.leading)
            )
        default:
            return AnyView(Circle()
                .fill(Color.clear)
                .frame(width: 77, height: 77, alignment: .center))
        }
    }

    private func formatDuration(_ t: UInt) -> String {
        if t == 0 {
            return "00:00"
        }

        let h = t / 3600
        let m = (t - h * 3600) / 60
        let s = t % 60
        return h == 0 ? String(format: "%02d:%02d", m, s) : String(format: "%02d:%02d:%02d", h, m, s)
    }

}

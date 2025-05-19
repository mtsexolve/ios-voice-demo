import SwiftUI
import ContactsUI

struct CallsKeyboard: View {
    @ObservedObject var activeCall: CallData
    @ObservedObject private var client = CallClientWrapper.instance

    private let contactPicker = ContactPickerView()

    private let logtag = "CallsKeyboard:"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .contentShape(Rectangle())

                VStack {
                    HStack {
                        CallButton(action: onMute, bgColor: grey,
                            label: Text(Strings.CallMute),
                            image: Image(systemName: activeCall.mute ? Images.CallMuteFill : Images.CallMute),
                            imageColor: activeCall.mute ? .red : .black)
                        CallButton(action: onDtmfKeyboard, bgColor: grey,
                            label: Text(Strings.Dtmf), image: Image(systemName: Images.Keys3x3))
                        .accessibilityIdentifier("DTMFButton")
                        //RouteButton(bgColor: grey, label: Text(client.currentAudioRoute))
                        RoutesListButton(bgColor: grey)
                    }
                    HStack {
                        CallButton(action: onAdd, bgColor: grey,
                            label: Text(Strings.Add), image: Image(systemName: Images.Add))
                        .accessibilityIdentifier("CallsKeyboardAddCallButton")
                        CallButton(action: onTransferKeyboard, bgColor: grey,
                            label: Text(Strings.CallTransfer), image: Image(systemName: Images.CallTransfer), imageColor: .black)
                        .accessibilityIdentifier("CallsKeyboardTransferCallButton")

                        switch (activeCall.state) {
                        case .CS_Connected:
                            CallButton(action: onHoldResume, bgColor: grey,
                                label: Text(Strings.CallHold), image: Image(systemName: Images.Pause))
                            .accessibilityIdentifier("CallsKeyboardHoldButton")
                        case .CS_OnHold:
                            CallButton(action: onHoldResume, bgColor: grey,
                                label: Text(Strings.CallResume), image: Image(systemName: Images.Play))
                            .accessibilityIdentifier("CallsKeyboardResumeButton")
                        default:
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 77, height: 77, alignment: .top)
                        }
                    }
                    HStack {
                        CallButton(action: onTerminate, bgColor: red,
                                   label: Text(Strings.CallTerminate), image: Image(systemName: Images.CallTerminate), imageColor: .white).accessibilityIdentifier("CallsKeyboardTerminateButton")
                    }
                }
                .padding(.bottom)
            } // vstack
        } // zstack

    func onMute() {
        if !client.conferenceActive {
            activeCall.call.mute(!activeCall.mute)
            return
        }

        let mute = !isMuted()
        client.calls.filter { return $0.call.inConference }
            .forEach { $0.call.mute(mute) }
    }

    func onDtmfKeyboard() {
        if (activeCall.state == .CS_Connected) {
            NotificationCenter.default.post(name: .showDtmfKeypad, object: nil, userInfo: nil)
        }
    }
    
    func onTransferKeyboard() {
        if (activeCall.state == .CS_Connected) {
            NotificationCenter.default.post(name: .showTransferKeypad, object: nil, userInfo: nil)
        }
    }

    func onAdd() {
        NotificationCenter.default.post(name: .showDialer, object: nil, userInfo: nil)
    }

    func onTerminate() {
        if client.conferenceActive {
            client.dismissConference()
        } else {
            activeCall.call.terminate()
        }
    }

    func onHoldResume() {
        switch (activeCall.state) {
        case .CS_Connected:
            activeCall.call.hold()
            break
        case .CS_OnHold:
            activeCall.call.resume()
            break
        default:
            break
        }
    }

    func isMuted() -> Bool {
        if !client.conferenceActive {
            return activeCall.mute
        }

        for data in client.calls {
            if data.call.inConference && data.mute {
                return true
            }
        }

        return false
    }
}

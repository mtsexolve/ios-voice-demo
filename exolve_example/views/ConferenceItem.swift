import SwiftUI

struct ConferenceItem: View {
    @ObservedObject var data: CallData

    private let logtag = "ConferenceItem:"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("GrayButtonBg"))
                .cornerRadius(10)

            HStack {
                getCallIcon()
                    .opacity(0.2)
                Spacer()
            }

            VStack {
                Text(data.number)
                    .font(font_reg)

                ZStack {
                    HStack {
                        if (data.mute) {
                            Image(systemName: Images.CallMute)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }

                    HStack {

                        Spacer()

                        Button(action: onRemove) {
                            HStack {
                                Image(systemName: Images.Close)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Color.black)
                            }
                        }

                        Spacer()

                        Button(action: onTerminate) {
                            HStack {
                                Image(systemName: Images.CallTerminate)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Color.red)
                            }
                        }

                        Spacer()
                    }
                }
            }
            .padding()
        }
    }

    func onTerminate() {
        NSLog("\(logtag) terminate")
        data.call.terminate()
    }

    func onRemove() {
        NSLog("\(logtag) remove")
        data.call.removeFromConference()
    }

    func getCallIcon() -> AnyView {
        switch (data.call.state) {
        case .CS_Connected:
            return AnyView(Image(systemName: Images.CallActive)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(width: 60, height: 60, alignment: .center)
                .padding(.leading))
        case .CS_OnHold:
            return AnyView(Image(systemName: Images.Pause)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.leading))
        default:
            return AnyView(Circle()
                .fill(Color.clear)
                .frame(width: 77, height: 77, alignment: .center))
        }
    }

}

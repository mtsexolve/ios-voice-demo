import SwiftUI

public struct RoutesListButton: View {
    @ObservedObject private var client = CallClientWrapper.instance
    var bgColor: Color?
    var imageColor: Color = Color.black

    public var body: some View {
        Menu {
            ForEach(client.audioRoutes, id: \.self) { data in
                Button(action: {
                    if !data.isActive {
                        client.setAudioRoute(data)
                    }
                }) {
                    HStack {
                        Text(data.name)
                        if data.isActive {
                            Spacer()
                            Image(systemName: Images.RouteActive)
                        }
                    }
                }
            }
        } label: {
            VStack {
                ZStack {
                    Circle()
                        .fill(bgColor ?? Color.clear)
                        .frame(width: 77, height: 77, alignment: .center)
                    getActiveRouteImage()
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30, alignment: .center)
                        .foregroundColor(imageColor)
                }
                getActiveRouteLabel()
                    .lineLimit(1)
                    .frame(width: 77)
            }
        }
    }

    private func getActiveRouteImage() -> Image {
        let activeRoute = client.audioRoutes.first { $0.isActive }
        if let activeRoute {
            return getRouteImage(activeRoute.route)
        }
        return Image(systemName: Images.RouteEarpiece)
    }

    private func getRouteImage(_ route: AudioRoute) -> Image {
        let image: Image
        switch (route) {
        case AudioRoute.AR_Bluetooth:
            image = Image(uiImage: UIImage(named: "bluetooth")!)
            break
        case AudioRoute.AR_Headset:
            image = Image(systemName: Images.RouteHeadset)
            break
        case AudioRoute.AR_Speaker:
            image = Image(systemName: Images.RouteSpeaker)
            break
        default:
            image = Image(systemName: Images.RouteEarpiece)
        }
        return image
    }

    private func getActiveRouteLabel() -> Text {
        let activeRoute = client.audioRoutes.first { $0.isActive }
        return Text(activeRoute != nil ? activeRoute!.name : "Earpiece")
    }

}


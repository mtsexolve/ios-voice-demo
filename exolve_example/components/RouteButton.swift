import SwiftUI
import AVKit

struct RoutePicker: UIViewRepresentable {
    typealias UIViewType = AVRoutePickerView
    let view = AVRoutePickerView()

    func makeUIView(context: Context) -> UIViewType {
        let view = AVRoutePickerView()
        view.backgroundColor = UIColor.clear
        view.tintColor = UIColor.black
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

public struct RouteButton<Label> : View where Label : View {
    var bgColor: Color?
    var label: Label
    public var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(bgColor ?? Color.clear)
                    .frame(width: 77, height: 77, alignment: .center)
                RoutePicker()
                    .frame(width: 65, height: 65)
            }
            label
        }
    }
}



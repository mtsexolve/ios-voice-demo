import SwiftUI

public struct CallButton<Label> : View where Label : View {
    var action: () -> Void
    var bgColor: Color?
    var label: Label
    var image: Image
    var imageColor: Color = Color.black
    public var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(bgColor ?? Color.clear)
                        .frame(width: 77, height: 77, alignment: .center)
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30, alignment: .center)
                        .foregroundColor(imageColor)
                }
                label
            }
        }
    }
}


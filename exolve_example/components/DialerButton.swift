import SwiftUI

public struct DialerButton<Label> : View where Label : View {
    var action: () -> Void
    var color: Color?
    var label: Label
    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color ?? Color.clear)
                    .frame(width: 77, height: 77, alignment: .center)
                label
            }
        }
    }
}

import SwiftUI

struct AccountTextField: View {
    @Binding var value: String
    var hint: String
    var body: some View {
        VStack {
            HStack {
                Text(hint)
                    .font(.subheadline)
                Spacer()
            }
            TextField(hint, text: $value)
            .disableAutocorrection(true)
            .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom)
    }
}

import SwiftUI

struct AccountCallTabView: View {
    @State var tabIndex = 1

    var body: some View {
        TabView(selection: $tabIndex) {
            DialerView()
                .tabItem {
                    Image(systemName: Images.CallCircle)
                        .resizable()
                    Text(Strings.Call)
                }
                .tag(0)
            AccountView()
                .tabItem {
                    Image(systemName: Images.AccountCircle)
                        .resizable()
                    Text(Strings.Account)
                }
                .tag(1)
            SettingsView()
                .tabItem {
                    Image(systemName: Images.Settings)
                        .resizable()
                    Text(Strings.Settings)
                }
                .tag(2)
        }
    }
}

import SwiftUI
import SwiftData

@main
struct Account_ManagerApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var rootViewID = UUID()
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView().id(rootViewID)
                    .modelContainer(for: [PasswordItem.self])
            } else {
                SignUpView().id(UUID())
            }
        }
        .onChange(of: isLoggedIn) { newValue in
                    if !newValue {
                        // Khi đăng xuất, thay đổi rootViewID để buộc ContentView bị giải phóng
                        rootViewID = UUID()
                    }
                }
    }
}

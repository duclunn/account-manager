import SwiftUI
import Foundation

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isAuthenticated = false
    @State private var users: [User] = []
    @State private var navigateToSignUp = false
    
    // Hiển thị Alert nếu sai mật khẩu
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @AppStorage("currentUserEmail") var currentUserEmail: String = ""
    
    var body: some View {
        if isAuthenticated {
            ContentView()
        } else {
            NavigationView {
                VStack(spacing: 16) {
                    Spacer()
                    Text("Đăng nhập")
                        .font(.largeTitle)
                        .bold()
                    // Trường nhập Email
                    TextField("Số di động hoặc email", text: $email)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    // Trường nhập Mật khẩu
                    SecureField("Mật khẩu", text: $password)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    // Nút Đăng nhập
                    Button(action: authenticate) {
                        Text("Đăng nhập")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    /*
                    // Liên kết quên mật khẩu
                    Button(action: {
                        print("Người dùng nhấn 'Quên mật khẩu'")
                        
                    }) {
                        Text("Bạn quên mật khẩu?")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                    */
                    NavigationLink(destination: ForgotPasswordView()) {
                                            Text("Bạn quên mật khẩu?")
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.top, 10)
                    Spacer()
                    
                    // Nút Tạo tài khoản mới
                    Button(action: {
                        navigateToSignUp = true
                    }) {
                        Text("Tạo tài khoản mới")
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 50) // khoảng cách từ trên xuống
                .onAppear {
                    loadUsers()
                }
                .fullScreenCover(isPresented: $navigateToSignUp) {
                    SignUpView()
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Thông báo"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationBarHidden(true)
        }
        
    }
    
    private func authenticate() {
        let hashedInput = sha256(password)
        print("Đăng nhập: Mật khẩu nhập vào sau khi băm là \(hashedInput)")
        
        if let user = users.first(where: { $0.email == email && $0.password == hashedInput }) {
            print("So sánh thành công, mật khẩu đã băm của tài khoản là \(user.password)")
            isAuthenticated = true
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            currentUserEmail = email
        } else {
            print("❌ Sai tài khoản hoặc mật khẩu")
            alertMessage = "Sai tài khoản hoặc mật khẩu"
            showAlert = true
        }
    }
    
    private func loadUsers() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("user.json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                users = try JSONDecoder().decode([User].self, from: data)
            } catch {
                print("Lỗi đọc user.json: \(error)")
            }
        }
    }
}

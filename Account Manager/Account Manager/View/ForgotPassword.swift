import SwiftUI
import Foundation
struct ForgotPasswordView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var email: String = ""
    @State private var navigateToReset = false

    var body: some View {
        
        VStack(spacing: 20) {
            // Back button
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.top)

            // Title & subtitle
            Text("Tìm tài khoản")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Nhập địa chỉ email của bạn.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Email field
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            // Continue button
            NavigationLink {
                if !email.isEmpty {
                    ResetPasswordView(email: email)
                }
            } label: {
                Text("Tiếp tục")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
/*
            Button {
                if !email.isEmpty {
                    navigateToReset = true
                }
            } label: {
                Text("Tiếp tục")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
       */
            Spacer()
            
        }
        .padding()
        .navigationBarHidden(true)
    }
}


struct ResetPasswordView: View {
    let email: String
    @Environment(\.presentationMode) private var presentationMode
    @State private var code: String = ""
    @State private var isVerified = false
    @State private var showImportPicker = false
    @State private var verificationMessage = ""
    @State private var navigateToChangePassword = false
    var body: some View {
        if !isVerified {
            VStack(spacing: 16) {
                // MARK: Back button
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.top)
                
                // MARK: Title & subtitle
                Text("Kiểm tra email")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Hãy tải lên file private key của \(email) mà bạn đã lưu khi tạo tài khoản.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                
               
                VStack(spacing: 20) {
                    Button(action: {
                        showImportPicker = true
                    }) {
                        Text("Tải file private_key.pem")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    

                // MARK: Other methods
                Button {
                    // TODO: other recovery methods
                } label: {
                    Text("Thử cách khác")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
                    if !verificationMessage.isEmpty {
                        Text(verificationMessage)
                            .foregroundColor(.red)
                    }
                }
                .sheet(isPresented: $showImportPicker) {
                    ImportDocumentPicker { selectedURL in
                        if let url = selectedURL {
                            processImportedPrivateKey(from: url)
                        } else {
                            verificationMessage = "Không tải được file, vui lòng thử lại."
                        }
                    }
                }
                .background(
                    NavigationLink(
                        destination: ChangePasswordView(email: email),
                        isActive: $navigateToChangePassword
                    ) { EmptyView() }
                    .hidden()
                        )
                Spacer()
            }
            .padding(.horizontal)
            .navigationBarHidden(true)
            
        } else {
            
        }
        
        
    }
    // MARK: Cần sửa lại (Lỗi)
    private func processImportedPrivateKey(from url: URL) {
        // Bắt đầu truy cập security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            verificationMessage = "Không thể truy cập file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            let cleaned = fileContent
                .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
                .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let components = cleaned.components(separatedBy: ",")
            if components.count >= 2, let nLoaded = components.first {
                navigateToChangePassword = true
            } else {
                verificationMessage = "File private key không hợp lệ."
            }
        } catch {
            verificationMessage = "Lỗi đọc file: \(error.localizedDescription)"
        }
        
    }
    
}
struct ChangePasswordView: View {
    let email: String
    // Lấy email hiện tại và lưu mật khẩu mới vào AppStorage
    @AppStorage("currentUserEmail") private var currentUserEmail: String = ""
    @AppStorage("currentUserPassword") private var currentUserPassword: String = ""
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            SecureField("Mật khẩu mới", text: $newPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Nhập lại mật khẩu", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            Button {
                saveNewPassword()
            } label: {
                Text("Lưu")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Đổi mật khẩu")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Thông báo"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage == "Mật khẩu đã được cập nhật!" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }

    private func saveNewPassword() {
        // 1) Kiểm tra đầu vào
        guard !newPassword.isEmpty && !confirmPassword.isEmpty else {
            alertMessage = "Vui lòng nhập đầy đủ thông tin."
            showAlert = true
            return
        }
        guard newPassword == confirmPassword else {
            alertMessage = "Mật khẩu không khớp."
            showAlert = true
            return
        }

        // 2) Băm mật khẩu mới và lưu vào AppStorage
        let hashed = sha256(newPassword)
        UserManager.shared.updatePassword(for: email, to: hashed)
        if email.lowercased() == currentUserEmail.lowercased() {
                    currentUserPassword = hashed
        }
        alertMessage = "Mật khẩu đã được cập nhật!"
        showAlert = true
    }
}
import Foundation

// MARK: - Model User


// MARK: - UserManager lưu vào UserDefaults (AppStorage)

final class UserManager {
    static let shared = UserManager()
    private let usersKey = "users"
    private let defaults = UserDefaults.standard

    /// Trả về mảng User
    private var users: [User] {
        get {
            guard let data = defaults.data(forKey: usersKey),
                  let arr = try? JSONDecoder().decode([User].self, from: data)
            else { return [] }
            return arr
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: usersKey)
            }
        }
    }

    /// Lấy User theo email
    func getUser(for email: String) -> User? {
        users.first { $0.email.lowercased() == email.lowercased() }
    }

    /// Cập nhật trường `password` (SHA‑256 hex) cho User
    func updatePassword(for email: String, to newHashedPassword: String) {
        var list = users
        if let idx = list.firstIndex(where: { $0.email.lowercased() == email.lowercased() }) {
            let old = list[idx]
            list[idx] = User(email: old.email,
                             password: newHashedPassword,
                             publicKey: old.publicKey)
        } else {
            // Nếu chưa tồn tại, thêm mới (không thường xài đến)
            list.append(User(email: email,
                             password: newHashedPassword,
                             publicKey: nil))
        }
        users = list
    }
}

#Preview {
    ChangePasswordView(email: "2@gmail")
}

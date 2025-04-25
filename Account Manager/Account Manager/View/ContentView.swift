import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

// MARK: - Định nghĩa User (đã lưu khi đăng ký)


// MARK: - ImportDocumentPicker (cho phép người dùng tải file private_key.pem)
struct ImportDocumentPicker: UIViewControllerRepresentable {
    var completion: ((URL?) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Cho phép mở file dạng plainText (.pem)
        let utTypes: [UTType] = [.plainText, UTType(filenameExtension: "pem")!]
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: utTypes)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var completion: ((URL?) -> Void)?
        init(completion: ((URL?) -> Void)?) {
            self.completion = completion
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion?(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion?(nil)
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var searchText = ""
    @Query var passwords: [PasswordItem]
    @State private var isShowingAddPassword = false
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserEmail") var currentUserEmail: String = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredPasswords) { item in
                    NavigationLink(destination: PasswordDetailView(passwordItem: item)) {
                        HStack {
                            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(item.website ?? "")")) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "globe")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                if let email = item.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mật khẩu")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đăng xuất") {
                       
                        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddPassword = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddPassword) {
                AddPasswordView(isPresented: $isShowingAddPassword)
            }
        }
    }
    
    var filteredPasswords: [PasswordItem] {
        let userPasswords = passwords.filter { $0.ownerEmail == currentUserEmail }
        if searchText.isEmpty {
            return userPasswords
        } else {
            return userPasswords.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// MARK: - PasswordDetailView cập nhật với xác thực private key
struct PasswordDetailView: View {
    let passwordItem: PasswordItem
    @State private var isEditing = false
    @State private var updatedEmail: String
    @State private var updatedPassword: String
    @State private var updatedWebsite: String
    @State private var copiedMessage: String? = nil
    @Environment(\.modelContext) private var modelContext
    
    // Sử dụng AppStorage để lấy email đăng nhập hiện hành
    @AppStorage("currentUserEmail") var currentUserEmail: String = ""
    // Sử dụng currentUserEmail làm accountEmail
    var accountEmail: String {
        currentUserEmail
    }
    
    // State để xác thực private key
    @State private var isVerified = false
    @State private var showImportPicker = false
    @State private var verificationMessage = ""
    
    init(passwordItem: PasswordItem) {
        self.passwordItem = passwordItem
        _updatedEmail = State(initialValue: passwordItem.email ?? "")
        _updatedPassword = State(initialValue: passwordItem.password ?? "")
        _updatedWebsite = State(initialValue: passwordItem.website ?? "")
    }
    
    var body: some View {
        VStack {
            if !isVerified {
                VStack(spacing: 20) {
                    Text("Để xem thông tin chi tiết tài khoản, vui lòng tải file mật khẩu đã lưu khi đăng ký.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        showImportPicker = true
                    }) {
                        Text("Tải file mật khẩu")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
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
            } else {
                // Nếu xác thực thành công, hiển thị thông tin chi tiết tài khoản
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(height: 80)
                    .overlay(
                        HStack {
                            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(updatedWebsite)")) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "globe")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text(passwordItem.name)
                                    .font(.title2)
                                    .bold()
                                Text("Sửa đổi lần cuối 28/9/24")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                    )
                    .padding()
                
                Form {
                    Section(header: Text("Tên người dùng")) {
                        if isEditing {
                            TextField("Nhập tên người dùng", text: $updatedEmail)
                        } else {
                            HStack {
                                Text(updatedEmail)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIPasteboard.general.string = updatedEmail
                                copiedMessage = "Tên người dùng đã được sao chép!"
                            }
                        }
                    }
                    
                    Section(header: Text("Mật khẩu")) {
                        if isEditing {
                            TextField("Nhập mật khẩu", text: $updatedPassword)
                        } else {
                            HStack {
                                Text(String(repeating: "*", count: updatedPassword.count))
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIPasteboard.general.string = updatedPassword
                                copiedMessage = "Mật khẩu đã được sao chép!"
                            }
                        }
                    }
                    
                    Section(header: Text("Trang web")) {
                        if isEditing {
                            TextField("Nhập URL", text: $updatedWebsite)
                        } else {
                            Link(destination: URL(string: updatedWebsite) ?? URL(string: "https://example.com")!) {
                                Text(updatedWebsite)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                    }
                }
                if let copiedMessage = copiedMessage {
                    Text(copiedMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .padding()
                }
            }
        }
        .navigationTitle(passwordItem.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Lưu" : "Sửa") {
                    if isEditing {
                        passwordItem.email = updatedEmail
                        passwordItem.password = updatedPassword
                        passwordItem.website = updatedWebsite
                        do {
                            try modelContext.save()
                        } catch {
                            print("Lỗi khi lưu dữ liệu: \(error)")
                        }
                    }
                    isEditing.toggle()
                }
            }
        }
    }
    
    // Hàm xử lý file private_key.pem được tải lên
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
                // Load thông tin người dùng dựa trên currentUserEmail
                if let user = loadCurrentUser(), let publicKeyString = user.publicKey {
                    let pubComponents = publicKeyString.components(separatedBy: ",")
                    if let nStored = pubComponents.first {
                        if nLoaded == nStored {
                            isVerified = true
                            verificationMessage = "Xác thực thành công!"
                        } else {
                            verificationMessage = "Private key không khớp với tài khoản của bạn."
                        }
                    } else {
                        verificationMessage = "Lỗi định dạng public key."
                    }
                } else {
                    verificationMessage = "Không tìm thấy thông tin tài khoản."
                }
            } else {
                verificationMessage = "File private key không hợp lệ."
            }
        } catch {
            verificationMessage = "Lỗi đọc file: \(error.localizedDescription)"
        }
    }
    
    // Hàm load user từ file user.json dựa trên currentUserEmail
    private func loadCurrentUser() -> User? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("user.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let users = try JSONDecoder().decode([User].self, from: data)
            return users.first { $0.email.lowercased() == currentUserEmail.lowercased() }
        } catch {
            print("Lỗi load user: \(error)")
            return nil
        }
    }
}

struct AddPasswordView: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var website = ""
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserEmail") var currentUserEmail: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nhãn", text: $name)
                    TextField("URL trang web", text: $website)
                    TextField("Tên người dùng", text: $email)
                    SecureField("Mật khẩu", text: $password)
                }
            }
            .navigationTitle("Mật khẩu mới")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        let newPassword = PasswordItem(name: name,
                                                       email: email,
                                                       password: password,
                                                       website: website,
                                                       ownerEmail: currentUserEmail)
                        modelContext.insert(newPassword)
                        do {
                            try modelContext.save()
                        } catch {
                            print("Lỗi khi lưu dữ liệu: \(error)")
                        }
                        isPresented = false
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

@Model
final class PasswordItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String?
    var password: String?
    var website: String?
    var ownerEmail: String?
    
    init(name: String, email: String? = nil, password: String? = nil, website: String? = nil, ownerEmail: String? = nil) {
        self.name = name
        self.email = email
        self.password = password
        self.website = website
        self.ownerEmail = ownerEmail
    }
}

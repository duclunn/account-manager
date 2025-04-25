import SwiftUI
import UniformTypeIdentifiers
import Foundation
import UIKit

// MARK: - DocumentPicker Wrapper
struct DocumentPicker: UIViewControllerRepresentable {
    let fileURL: URL
    var completion: ((URL?) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Sử dụng forExporting để cho phép người dùng chọn nơi lưu file
        let controller = UIDocumentPickerViewController(forExporting: [fileURL])
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

// MARK: - File Document cho Private Key (nếu cần)
struct PrivateKeyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}

// MARK: - Hàm băm SHA‑256
func sha256(_ input: String) -> String {
    var message = [UInt8](input.utf8)
    let originalBitLength = UInt64(message.count * 8)
    message.append(0x80)
    while ((message.count * 8) % 512) != 448 {
        message.append(0)
    }
    for i in (0..<8).reversed() {
        message.append(UInt8((originalBitLength >> (i * 8)) & 0xff))
    }
    
    var h0: UInt32 = 0x6a09e667
    var h1: UInt32 = 0xbb67ae85
    var h2: UInt32 = 0x3c6ef372
    var h3: UInt32 = 0xa54ff53a
    var h4: UInt32 = 0x510e527f
    var h5: UInt32 = 0x9b05688c
    var h6: UInt32 = 0x1f83d9ab
    var h7: UInt32 = 0x5be0cd19
    
    let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
        0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
        0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
        0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
        0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
        0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
        0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ]
    
    let chunkSize = 64
    for chunkStart in stride(from: 0, to: message.count, by: chunkSize) {
        let chunk = Array(message[chunkStart..<chunkStart+chunkSize])
        var w = [UInt32](repeating: 0, count: 64)
        for i in 0..<16 {
            let j = i * 4
            w[i] = (UInt32(chunk[j]) << 24) |
                   (UInt32(chunk[j+1]) << 16) |
                   (UInt32(chunk[j+2]) << 8) |
                   UInt32(chunk[j+3])
        }
        for i in 16..<64 {
            let s0 = rightRotate(w[i-15], by: 7) ^ rightRotate(w[i-15], by: 18) ^ (w[i-15] >> 3)
            let s1 = rightRotate(w[i-2], by: 17) ^ rightRotate(w[i-2], by: 19) ^ (w[i-2] >> 10)
            w[i] = w[i-16] &+ s0 &+ w[i-7] &+ s1
        }
        
        var a = h0
        var b = h1
        var c = h2
        var d = h3
        var e = h4
        var f = h5
        var g = h6
        var h = h7
        
        for i in 0..<64 {
            let S1 = rightRotate(e, by: 6) ^ rightRotate(e, by: 11) ^ rightRotate(e, by: 25)
            let ch = (e & f) ^ ((~e) & g)
            let temp1 = h &+ S1 &+ ch &+ k[i] &+ w[i]
            let S0 = rightRotate(a, by: 2) ^ rightRotate(a, by: 13) ^ rightRotate(a, by: 22)
            let maj = (a & b) ^ (a & c) ^ (b & c)
            let temp2 = S0 &+ maj
            
            h = g
            g = f
            f = e
            e = d &+ temp1
            d = c
            c = b
            b = a
            a = temp1 &+ temp2
        }
        h0 = h0 &+ a
        h1 = h1 &+ b
        h2 = h2 &+ c
        h3 = h3 &+ d
        h4 = h4 &+ e
        h5 = h5 &+ f
        h6 = h6 &+ g
        h7 = h7 &+ h
    }
    
    let hashParts: [UInt32] = [h0, h1, h2, h3, h4, h5, h6, h7]
    return hashParts.map { String(format: "%08x", $0) }.joined()
}

func rightRotate(_ value: UInt32, by: UInt32) -> UInt32 {
    return (value >> by) | (value << (32 - by))
}


// MARK: - SignUpView sử dụng DocumentPicker
struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var password2: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToLogin = false
    
    // State để kích hoạt DocumentPicker
    @State private var isShowingDocPicker = false
    @State private var tempPrivateKeyURL: URL? = nil  // URL file tạm chứa private key
    
    var body: some View {
        VStack {
            Text("Đăng ký")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .autocapitalization(.none)
                .padding(.horizontal)
            
            SecureField("Mật khẩu", text: $password)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .padding(.horizontal)
            
            SecureField("Nhập lại mật khẩu", text: $password2)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .padding(.horizontal)
            
            Button(action: handleSignUp) {
                Text("Đăng ký")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Button(action: {
                navigateToLogin = true
            }) {
                Text("Đã có tài khoản? Đăng nhập")
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thông báo"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK"), action: {
                      if alertMessage == "Tạo tài khoản thành công! Hãy lưu lại file mật khẩu của bạn." {
                          // Sau khi alert, hiển thị DocumentPicker để chọn nơi lưu file
                          isShowingDocPicker = true
                      }
                  }))
        }
        .sheet(isPresented: $isShowingDocPicker, onDismiss: {
            navigateToLogin = true
        }) {
            if let fileURL = tempPrivateKeyURL {
                DocumentPicker(fileURL: fileURL) { selectedURL in
                    if let url = selectedURL {
                        print("Private key đã được di chuyển đến: \(url)")
                    } else {
                        print("Người dùng hủy lưu file")
                    }
                }
            } else {
                Text("Không tìm thấy file private_key.pem")
            }
        }
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView()
        }
    }
    
    private func handleSignUp() {
        // Kiểm tra dữ liệu nhập vào
        guard !email.isEmpty, !password.isEmpty, !password2.isEmpty else {
            alertMessage = "Email và mật khẩu không được để trống"
            showAlert = true
            return
        }
        guard password == password2 else {
            alertMessage = "Mật khẩu không khớp!"
            showAlert = true
            return
        }
        let existingUsers = readUsers() ?? []
        if existingUsers.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            alertMessage = "Email đã được đăng ký!"
            showAlert = true
            return
        }
        
        // Băm mật khẩu
        let hashedPassword = sha256(password)
        print("Đăng ký: Mật khẩu băm là \(hashedPassword)")
        
        // Sinh cặp khóa RSA (các hàm RSA được tích hợp từ RSAHelper.swift)
        guard let keyPair = generateRSAKeyPair() else {
            alertMessage = "Lỗi tạo cặp khóa RSA"
            showAlert = true
            return
        }
        
        // Lưu public key (lưu dưới dạng chuỗi "n,e")
        let publicKeyString = "\(keyPair.publicKey.n),\(keyPair.publicKey.e)"
        let newUser = User(email: email, password: hashedPassword, publicKey: publicKeyString)
        var users = readUsers() ?? []
        users.append(newUser)
        writeUsers(users)
        
        // Tạo file tạm chứa nội dung PEM cho private key
        let pemContent = """
        -----BEGIN PRIVATE KEY-----
        \(keyPair.privateKey.n),\(keyPair.privateKey.d)
        -----END PRIVATE KEY-----
        """
        //let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("private_key.pem")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(email.components(separatedBy: "@").first ?? email).pem")
        do {
            try pemContent.write(to: tempURL, atomically: true, encoding: .utf8)
            tempPrivateKeyURL = tempURL
        } catch {
            print("Lỗi tạo file tạm: \(error)")
        }
        
        alertMessage = "Tạo tài khoản thành công! Hãy lưu lại file mật khẩu của bạn."
        showAlert = true
    }
    
    private func readUsers() -> [User]? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("user.json")
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([User].self, from: data)
        } catch {
            print("Lỗi đọc user.json: \(error)")
            return nil
        }
    }
    
    private func writeUsers(_ users: [User]) {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("user.json")
        do {
            let data = try JSONEncoder().encode(users)
            try data.write(to: fileURL)
        } catch {
            print("Lỗi ghi file user.json: \(error)")
        }
    }
}

import Foundation

// MARK: - Tính lũy thừa modulo
func modExp(_ base: UInt64, _ exp: UInt64, _ mod: UInt64) -> UInt64 {
    var result: UInt64 = 1
    var base = base % mod
    var exp = exp
    while exp > 0 {
        if exp & 1 == 1 {  // nếu số mũ lẻ
            result = (result * base) % mod
        }
        exp >>= 1  // chia cho 2
        base = (base * base) % mod
    }
    return result
}

// MARK: - Tìm nghịch đảo modulo sử dụng thuật toán Euclid mở rộng
func modInverse(_ a: UInt64, _ m: UInt64) -> UInt64? {
    var m0 = m
    var x0: Int64 = 0, x1: Int64 = 1
    var a = Int64(a), m = Int64(m)
    if m == 1 { return nil }
    
    while a > 1 {
        let q = a / m
        (a, m) = (m, a % m)
        (x0, x1) = (x1 - q * x0, x0)
    }
    if x1 < 0 { x1 += Int64(m0) }
    return UInt64(x1)
}

// MARK: - Kiểm tra số nguyên tố bằng thuật toán Miller‑Rabin
func isPrime(_ n: UInt64, iterations: Int = 5) -> Bool {
    if n < 2 { return false }
    if n == 2 || n == 3 { return true }
    if n % 2 == 0 { return false }
    
    var s = 0
    var d = n - 1
    while d % 2 == 0 {
        d /= 2
        s += 1
    }
    
    for _ in 0..<iterations {
        let a = 2 + UInt64(arc4random_uniform(UInt32(n - 3)))
        var x = modExp(a, d, n)
        if x == 1 || x == n - 1 { continue }
        var found = false
        for _ in 0..<s - 1 {
            x = modExp(x, 2, n)
            if x == n - 1 {
                found = true
                break
            }
        }
        if !found { return false }
    }
    return true
}

// MARK: - Sinh số nguyên tố lớn (dùng cho demo, với phạm vi UInt64)
func generateLargePrime() -> UInt64 {
    while true {
        let candidate = UInt64(arc4random_uniform(900_000_000)) + 100_000_000
        if isPrime(candidate) {
            return candidate
        }
    }
}



// Sinh cặp khóa RSA
func generateRSAKeyPair() -> RSAKeyPair? {
    let p = generateLargePrime()
    let q = generateLargePrime()
    guard p != q else { return generateRSAKeyPair() }
    
    let n = p * q
    let phi = (p - 1) * (q - 1)
    let e: UInt64 = 65537
    guard let d = modInverse(e, phi) else { return nil }
    
    return RSAKeyPair(publicKey: (n, e), privateKey: (n, d))
}

// MARK: - Các hàm chuyển đổi chuỗi và mã hoá/giải mã

// Chuyển chuỗi thành số: nối mã ASCII của các ký tự
func stringToUInt64(_ str: String) -> UInt64 {
    let asciiCodes = str.utf8.map { String($0) }
    let combined = asciiCodes.joined()
    return UInt64(combined) ?? 0
}

// Chuyển số về chuỗi theo quy ước: mỗi 2 chữ số biểu thị 1 ký tự ASCII
func uint64ToString(_ num: UInt64) -> String {
    let numStr = String(num)
    var result = ""
    var temp = ""
    for ch in numStr {
        temp.append(ch)
        if temp.count == 2, let ascii = UInt8(temp) {
            result.append(Character(UnicodeScalar(ascii)))
            temp = ""
        }
    }
    return result
}

// Mã hoá chuỗi (ví dụ: email) bằng khóa công khai RSA
func encryptEmail(_ email: String, publicKey: (n: UInt64, e: UInt64)) -> UInt64 {
    let message = stringToUInt64(email)
    return modExp(message, publicKey.e, publicKey.n)
}

// Giải mã chuỗi từ cipherText sử dụng khóa riêng RSA
func decryptEmail(_ cipher: UInt64, privateKey: (n: UInt64, d: UInt64)) -> String {
    let decrypted = modExp(cipher, privateKey.d, privateKey.n)
    return uint64ToString(decrypted)
}

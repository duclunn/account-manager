//
//  model.swift
//  Account Manager
//
//  Created by duclun on 21/04/2025.
//

// MARK: User
struct User: Codable {
    let email: String
    let password: String
    let publicKey: String?
}

// MARK: Cấu trúc lưu trữ cặp khóa RSA
struct RSAKeyPair {
    let publicKey: (n: UInt64, e: UInt64)
    let privateKey: (n: UInt64, d: UInt64)
}

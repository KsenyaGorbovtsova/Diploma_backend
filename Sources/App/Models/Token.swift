//
//  Token.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 29/11/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication


final class Token: Codable {
    var id: UUID?
    var token: String
    var userId: User.ID
    
    init (token: String, userId: User.ID) {
        self.token = token
        self.userId = userId
    }
    
}

extension Token: PostgreSQLUUIDModel {}
extension Token: Migration {}
extension Token: Content {}
extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 16)
        return try Token(token: random.base64EncodedString(), userId: user.requireID())
    }
}
extension Token: Authentication.Token {
    typealias UserType = User
    
    static var userIDKey: UserIDKey {
        return \Token.userId
    }
    
    static var tokenKey: TokenKey {
        return \Token.token
    }
}

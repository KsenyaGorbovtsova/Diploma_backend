//
//  User.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 28/11/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Fluent
import Authentication

final class User: PostgreSQLUUIDModel, Model {
    
    var id: UUID?
    var firstName: String?
    var secondName: String?
    var email: String
    var password: String
    
    init( email: String, password: String, firstName: String? = "Guest", secondName: String? = " ") {
        //self.id = id
        self.firstName = firstName
        self.secondName = secondName
        self.email = email
        self.password = password
        
    }
}


extension User: Parameter {}
extension User: Content {}
extension User: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            
            builder.unique(on: \.email)
            
        }
    }
}

extension User: BasicAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \User.email
    }
    
    static var passwordKey: WritableKeyPath<User, String> {
        return \User.password
    }
}
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}


/*struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase
    
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        let password = try? BCrypt.hash("password") // NOT do this for production
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        
        let user = User(email: "ddd", password: hashedPassword)
        return user.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return .done(on: conn)
    }
}
*/

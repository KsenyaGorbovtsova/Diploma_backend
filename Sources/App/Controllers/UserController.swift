//
//  UserController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 28/11/2018.
//

import Foundation
import Vapor
import Fluent
import Crypto
import HTTP
final class UserController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped( "users")
        usersRoute.post(use: createUser)
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let guardAuthMiddleware = User.guardAuthMiddleware()
        
        let basicProtected = usersRoute.grouped(basicAuthMiddleware, guardAuthMiddleware)
        basicProtected.post("login", use: login)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let tokenProtected = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenProtected.delete(User.parameter, use: deleteUser)
        tokenProtected.get(User.parameter, use: getUser)
        tokenProtected.patch(UserContent.self, at: User.parameter, use: updateUser)
        tokenProtected.get(use: getPublicUsers)
        tokenProtected.get("logout", use: logout)
    }
    
    func getPublicUsers(_ req: Request) throws -> Future<[PublicUser]>{
        let users = User.query(on:req).all()
        return users.map { users -> [PublicUser] in
            try users.map { user in
                 PublicUser(
                    firstName: user.firstName,
                    secondName: user.secondName,
                    email: user.email)
            }
        }
    }
    func getUser (_ req: Request) throws -> Future<PublicUser> {
        let user = try req.parameters.next(User.self)
        return user.map { user -> PublicUser in
            PublicUser(
                firstName: user.firstName,
                secondName: user.secondName,
                email: user.email)
        }
    }

    func createUser(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { (user) in
            user.password = try BCrypt.hash(user.password)
            return user.save(on: req)
        }
    }
    func updateUser (_ req: Request, _ body: UserContent) throws -> Future<User> {
        let user = try req.parameters.next(User.self)
        return user.map(to: User.self,  { user in
            user.id = body.id ?? user.id
            user.firstName = body.firstName ?? user.firstName
            user.secondName = body.secondName ?? user.secondName
            user.email = body.email ?? user.email
            user.password = try BCrypt.hash(body.password ?? user.password)
            return user
        }).update(on: req)
    }
    func login(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
    func logout(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try Token
            .query(on: req)
            .filter(\Token.userId == user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }
    func deleteUser(_ req: Request) throws -> Future<HTTPStatus>{
        return try req.parameters.next(User.self).flatMap { (user) in
            return user.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }
    struct PublicUser: Content {
        var firstName: String?
        var secondName: String?
       var email: String
    }
    
    struct UserContent: Content {
        var id: UUID?
        var firstName: String?
        var secondName: String?
        var email: String?
        var password: String?
    }
    
}

//
//  UserController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 28/11/2018.
//

import Foundation
import Vapor
import Fluent
import FluentSQL
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
        tokenProtected.get(User.parameter, use: getPublicUser)
        tokenProtected.patch(UserContent.self, at: User.parameter, use: updateUser)
        usersRoute.get(use: getPublicUsers)
        tokenProtected.get("logout", use: logout)
        tokenProtected.post(User.parameter, "addpractice", use: addPracticeToUser)
        tokenProtected.get(User.parameter, "practices", use: getPractices)
        tokenProtected.delete(User.parameter, "delete", use: deletePracticeFromUser)
        tokenProtected.post(User.parameter, "addfriend", use: addFriendtoUser)
        tokenProtected.delete(User.parameter, "deletefriend", use: deleteFriendFromUser)
        tokenProtected.get(User.parameter, "friends", use: getFriends)
        tokenProtected.get("search", use: searchFriend )
        
    }
    
    //-------тренировки одного пользователя------
    func getPractices (_ req: Request) throws -> Future<[Practice]> {
        return try req.parameters.next(User.self).flatMap { practice in
            return try practice.containg.query(on: req).all()
        }
    }
    //-------друзья пользователя-----------
    func getFriends (_ req: Request) throws -> Future<[User]> {
        return try req.parameters.next(User.self).flatMap{ friend in
            return try friend.makeFriend.query(on: req).all()
        }
    }
    //------добавить тренировку пользователю
    func addPracticeToUser(_ req: Request) throws -> Future <[String:User]> {
        let current = try req.parameters.next(User.self)
        let containingId = req.content.get(Practice.ID.self, at: "contain")
        let contain = containingId.and(result: req).flatMap(Practice.find).unwrap(or: Abort(.badRequest, reason: "no such id"))
        return flatMap (to: (current: User, containing: Practice).self, current, contain) { current, contain in
            return current.addPractice( practice: contain,  on: req)
            }.map {users -> [String: User] in
                return ["current": users.current]
        }
    }
    //-----удалить тренировку у пользователя-----
    func deletePracticeFromUser (_ req: Request) throws -> Future<HTTPStatus> {
        let current = try req.parameters.next(User.self)
        let deletedId = req.content.get(Practice.ID.self, at: "delete")
        let deleted = deletedId.and(result: req).flatMap(Practice.find).unwrap(or: Abort( .badRequest, reason: "no such uid"))
        return flatMap(to: HTTPStatus.self, current, deleted) {current, deleted in
            return current.deletePractice(practice: deleted, on: req).transform(to: .noContent)
        }
    }
    //------получить публичные данные пользователей-------
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
    //-------добавить друга пользователю---------------
    func addFriendtoUser(_ req: Request) throws -> Future <[String: User]> {
        let current =  try req.parameters.next(User.self)
        let makeFriendId = req.content.get(User.ID.self, at: "makeFriend")
        let makeFriend = makeFriendId.and(result: req).flatMap(User.find).unwrap(or: Abort(.badRequest, reason: "no such id"))
        return flatMap(to: (current: User, makeFriend: User).self, current, makeFriend) { current, makeFriend in
        return current.addFriend(friend: makeFriend, on: req)
            }.map {users -> [String:User] in
                return ["makeFriend":users.makeFriend]
        }
    }
    //-------удалить друга у пользователя----------------
    func deleteFriendFromUser (_ req: Request) throws -> Future<HTTPStatus>{
        let current = try req.parameters.next(User.self)
        let deletedId = req.content.get(User.ID.self, at: "delete")
        let deleted = deletedId.and(result: req).flatMap(User.find).unwrap(or: Abort (.badRequest, reason: "no such uid"))
        return flatMap(to: HTTPStatus.self, current, deleted) { current, deleted in
            return current.deleteFriend(friend: deleted, on: req).transform(to: .noContent)
        }
    }
    //----------поиск пользователя по имени---------host/users/search?email=email
    func searchFriend (_ req: Request) throws -> Future<[User]> {
        let email = try req.query.get(String.self, at: "email")
        return User.query(on: req).group(.or) { query in
            query.filter(\.email, .like, "\(email)%")
            }.all()
    }
    
    //-------получить публичные данные пользователя------
    func getPublicUser (_ req: Request) throws -> Future<PublicUser> {
        let user = try req.parameters.next(User.self)
        return user.map { user -> PublicUser in
            PublicUser(
                firstName: user.firstName,
                secondName: user.secondName,
                email: user.email)
        }
    }
    //--------создание пользователя-------
    func createUser(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { (user) in
            user.password = try BCrypt.hash(user.password)
            return user.save(on: req)
        }
    }
    //-----редактирование пользователя-----
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
    //------логин------
    func login(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
    //------выход------
    func logout(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try Token
            .query(on: req)
            .filter(\Token.userId == user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }
    //------удаление пользователя-------
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

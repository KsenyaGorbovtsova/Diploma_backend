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
                    email: user.email,
                    image: user.image)
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
                email: user.email,
                image: user.image)
        }
    }
    //--------создание пользователя-------
    func createUser(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { (user) in
            user.password = try BCrypt.hash(user.password)
            if user.image == nil {
                user.image = Data(base64Encoded: "image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAcIAAAHCCAMAAABLxjl3AAAAkFBMVEXi4uKsrKzh4eGurq7f39+vr6/a2trFxcWxsbHV1dW7u7uzs7POzs7Z2dm5ubnHx8fCwsKwsLDExMTQ0NDT09O+vr64uLjKysq0tLTAwMDDw8O2trbW1ta9vb3Ly8vY2Ni1tbXBwcHc3NzR0dG8vLzU1NTe3t7Nzc2rq6utra3g4ODPz8/IyMi6urrb29vJyck1q1GOAAAJkUlEQVR4XuzOuRGEQAwAsKvE3uX/r//uCIkIyGBGqkC/RwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABYMteIetlizGw+MGfoo3Zlnm6Uvf7b46V3TvbuRSlxJQwCcE8SroqIIKirXARjJwK+/9udqq2trdo96opymU76e4VUZf7b/PM4vNs0+BnFePHcRFRsO71uczdpd91BFKxcXrb5NenqPMdpWXbeDfyWH+tHnIqVL93APRhPcpyAzS5T7ktYjXBcVk7n3K9BP8fRWN5KuX/htoejsOai4IF0n3Bw1rwNPKBxBwdl29vAA7vo4GCsvAo8gtUWh2HDNo+jWCfYP2tueDxnT9gzK1uBR/WQY59s2eaxFa8J9sWyFU/hpof9sM6Ap1FMsQ/WDzyZVYnvsnzDUzqb4XvsqcHTChN8gyX9wJNbZfgqyy4Yg3YPX2OPN4xD2sFXWLPNWBRD7M7uU8YjTLErGxWMSh+7sefAyCwS7MDWjM8qwadZizHalPgk6zNO3QSfYhP+JPsvtWfG6xr/ZsvAiF3hX+y+YNSm+Jg1G4xbWOIjlp0xdsUM77Nkw/i1c7zLWlRwkeAdtqSGO7zNmilFDPEWS+ZUkW7xBruijnGC/7GnQCF9/M2yAZWEDv5i19RyluAPNuJbdAreVrapJvxRaLNL6pkn+M1mgYKm+M3GVJRm+MXOqWmBnwzlgD/JRjS2pqoLGABkKWU9wQC0qGsMA/KCwkYw3FHZHJYXlLaET0Jqc1BaNihuhpqbUt0D6i05o7qwdadXmnu/K+prJKixPFAfhy5wq9ugxs6ozQHNPath7fKoLBdK26yIJmqqw6pYe3hU3Y3/o/K2qKUtq2PqJoUktyu6rI40QQ2VBSuk45RCXd8lbnVdH4WCfBimrJQeaqdJcc4MX1gtC+96Ujd2NKOucI1bjSvdGatm6bEZdWsHpOouXV4T42nSBcV5+GJDcc4qblg5OeqlQXEudAdq8xqhktUz9ACiumfUyoziXJ7p+BOqW7J6Wv6EUrz5YsjqufM2biWenvEn1Df0WSjO4Yy+kZMKAU7t1bjA9gp5LnPLc7OpXgq3fNUNKM5bvOasnMwXm8Sl3r8mxhstXynOOy+WvhYTG5dnJqiZMrBiRl6Or+7R78SIa6B2+hTndwyHDkjj4nbTOepn4CK3ugdHM+omrJIVamjm2oy6JPVFe3XXPgrj4XsV1zgpZ4bOCr0+KGSop5a3OqvrOaWIhP+kIUdd9d1oUtfzMyPy5o5H1U2d16vLCl9pUndLfWeotXvfsZf3g+qKHPX24tE1dUmb2kITdTfx0Iy6MqW0e1ifyjYwlA0Km8GAV/WT0MoBVYUeDACm6gVuS+bUVDxCm7eTrqHNg92DBL8YtoX6/K+tve7JEc2pYxmbBfWxNWtRyxjanBwWW/zNeoX6OnybUMcDtHnZczvDWyxvU0PoQJsziyneY89UcIv32YLxm5d4nyUXjN3gER+x7IZxK3r4mD02GLOwxL/YfaEejNqoYLT6+AxbBvUXl20Y1O+h2XlghBb4PHsJjM4ddmHLQv0ctKdCfezX7huMR3jG7mx7w1j8x7697igKREEAPg22DSreVx0mNs0g7JGZxvd/u/25+2MTM9IXJqnvFSo5yUmq0pZeAb3lacjm9BpItjwF645eBoeUYxMqoRFgMByXbGkcSEqOyXY0GjQpxyI25AIMJ45jl5MbkCjBEdw6cgbmlkNbHskpOOw4pPsmIceg3wsOZjGQB1CsOYxlQ57ASrJ/d9WTN9Cfpe8Atx15Bf1Xyv6I+oO8g/6csR9pGSpA+Hxn97JzT+FA/nZnp+whobBgpg27slNxLigUasnjybqleKAamaJ8O1JsMOjFnV+y3lQ0DZC0XwvJ3yHWqpnRtMD8d2klP3c/1TqnqYIu16o2O/6f1Fy3+jjQzwBV1eq/mqp68rcDAAAAAAAAAAAAAAAAAAAAwFCtdF1bY8w/EyhjzKmuHzovaLqg+lS/TMbPpGZR6ok1aaBr1O3C37Oz29Wc4oMkf1wzflVq4xaCodpYwaNd9seewoMPfUvZFWEDrytg2Lyza9m+pTCgUBf2Q9ZH8g26x4V9kmVB/kDSLAR7Z84z8gKGUnIY4pqTc9De/rBzdzvJA1EUhvfMtEMN/QqKJfCVUCJJu6YK3v/dedIYEzT8SGC2Xc8tvNkH62TjljatlSuirl3g1tJRI1dCycThHszSyxVQMuoDMiIDXqT81cigbhRwd6WXC5FdO8TATBO5BM3GiIV76+RcVM8RkyyXs1AyRWwKL6ejPEV8zMlv18kXiFO2lROQnRhEq0zkGPIVYpbOjgSg94CeykOkfYH4PT7LTygPUOG/le9Qt4QW1V4OkV9AD3c4L6gNUGVq5SuyS2hTvcgnkmYOfdKV9EjqDBqZtg9ArwE69euCnqDXrhOyJTTbNNzzO+iWeRm2poJ2biVD5sfQL2xluP6l+AtMLkNVKy/IgVg7gA1ZMBZrGZ4H5QXZsHYf7dzbctpAEATQ2dXFAgExF5sQxyADgZbA5P//Lg+pStllG/shD+rZPv9Aie6ZHThztLSUBbwJc0vJdgp/wsLScajhUTuwVOQNfMrGloY4gVfF1pJwC7+azhJwhGd35t8gwLWzebctQE3RomvgXVaaa4/wr87NsTNSMIzm1i4gCTPzqsyQiJH5lNdIRbsxl/ZIR5WrlekftTRli6SczJv4gLRkF3PmBqmZRJXbfaLCO9ZITyj1CpTdfTQ3NgFJWpoXsUGa2ovmE+yezYcygJv67iHSNe3MgR1SNlMkZBdK7VqwGxq7bYvE7YzcCqmro3oZdmv2QMFNweIXyGnqdA8BstxoLSAAcGO0GggAtAf2H6HMjNQE3PQ1HOAvAc7smVCKzgiNQU4VzR3+EVTR6BwCXpC50fmGl2RibGKBV2RsZE54TZ7YY720OXuikCX7tUP5bkxihjdkY0TmeEtu2e+TSBGNRh7ATSulS7xH9kbjAdwUDS94nxzZX8LIkH17VELO/n9URkZhjY/II/vak7SdEehacFO63+Fj8sMIPIGcJk4VrpCD9V6Ja2TEHilkxb7ELZX13hRXSUkwpeCmacUI18mKPRVKTX8hQXLrtS7gE7KwXvuJz8iZfXdN9uy3K6VmXz+U0FmPxRafkgF7NyNr9om9zNiXgOWZvV6Tiv1IgoRo/VXjC2Rr/RXATaniAHJagRqAnIruE8jpltdvkNNL0Rm+Qhr2UZPU7BeDJLP/6Q/qOTFj+4uw2wAAAABJRU5ErkJggg==")!
            }
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
            user.image = try body.image ?? user.image
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
        var image: Data?
    }
    
    struct UserContent: Content {
        var id: UUID?
        var firstName: String?
        var secondName: String?
        var email: String?
        var password: String?
        var image: Data?
    }
    
}

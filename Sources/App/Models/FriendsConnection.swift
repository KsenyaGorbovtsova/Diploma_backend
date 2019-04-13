//
//  FriendsConnection.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 13/04/2019.
//

import Foundation
import FluentPostgreSQL

final class FriendsConnection: PostgreSQLPivot {
    
    
    
    var id: Int?
    static var leftIDKey: WritableKeyPath<FriendsConnection, UUID> = \.userId
    static var rightIDKey: WritableKeyPath<FriendsConnection, UUID> = \.friendId
    typealias Left = User
    typealias Right = User
    
    var userId: UUID
    var friendId: UUID
    
    init (left: User, right: User) throws {
        self.userId = try left.requireID()
        self.friendId = try right.requireID()
    }
}

extension FriendsConnection: Migration{}
extension User {
    var makeFriend: Siblings<User, User, FriendsConnection> {
        return self.siblings(\FriendsConnection.userId, \FriendsConnection.friendId)
    }
    
    func addFriend (friend: User, on connection: DatabaseConnectable) -> Future<(current: User, makeFriend: User )> {
        return Future.flatMap(on: connection) {
            let pivot = try FriendsConnection(left: self, right: friend)
            return pivot.save(on: connection).transform(to: (self, friend))
        }
    }
    func deleteFriend (friend: User, on connection: DatabaseConnectable) -> Future<(current: User, deleted: User)> {
        return self.makeFriend.detach(friend, on: connection).transform(to: (self,friend))
    }
}

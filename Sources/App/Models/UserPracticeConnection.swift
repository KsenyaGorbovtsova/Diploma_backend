//
//  UserPracticeConnection.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 06/12/2018.
//

import Foundation
import FluentPostgreSQL

final class UserPracticeConnection: PostgreSQLPivot {
    
    var id: Int?
    
    static var leftIDKey: WritableKeyPath<UserPracticeConnection, UUID> = \.userId
    static var rightIDKey: WritableKeyPath<UserPracticeConnection, UUID> = \.practiceId
    typealias Left = User
    typealias Right = Practice
    
    var userId: UUID
    var practiceId: UUID
    
    init (left: User, right: Practice) throws {
        self.userId = try left.requireID()
        self.practiceId = try right.requireID()
    }
    
}

extension UserPracticeConnection: Migration {}
extension User {
    var containg: Siblings <User, Practice, UserPracticeConnection> {
        return self.siblings(\UserPracticeConnection.userId, \UserPracticeConnection.practiceId)
    }
    func addPractice (practice: Practice, on connection: DatabaseConnectable) -> Future<(current: User, containing: Practice)> {
        return Future.flatMap(on: connection) {
            let pivot = try UserPracticeConnection(left: self, right: practice)
            return pivot.save(on: connection).transform(to: (self, practice))
        }
    }
    func deletePractice (practice: Practice, on connection: DatabaseConnectable) -> Future <(current: User, deleted: Practice)>
    {
        return self.containg.detach(practice, on: connection).transform(to: (self, practice))
    }
}

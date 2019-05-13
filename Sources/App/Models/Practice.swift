//
//  Practice.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 08/11/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Practice: PostgreSQLUUIDModel, Hashable {
    static func == (lhs: Practice, rhs: Practice) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    var id: UUID?
    var status: Bool
    var name: String
    var owner: UUID
    var date: Date?
    var repeatAfter: Int?
    public init ( status: Bool, name: String, owner: UUID, date: Date, repeatAfter: Int) {
        self.date = date
        self.repeatAfter = repeatAfter
        self.status = status
        self.name = name
        self.owner = owner
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Practice: Content{}
extension Practice: Migration{}
extension Practice: Parameter{}


//
//  Practice.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 08/11/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Practice: PostgreSQLUUIDModel {
    
    var id: UUID?
    var status: Bool
    var name: String
    var owner: UUID
    public init ( status: Bool, name: String, owner: UUID) {
       
        self.status = status
        self.name = name
        self.owner = owner
    }
}

extension Practice: Content{}
extension Practice: Migration{}
extension Practice: Parameter{}


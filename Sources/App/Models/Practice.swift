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
    var date: Date
    var status: Bool
    var name: String
    
    public init (date: Date, status: Bool, name: String) {
        self.date = date
        self.status = status
        self.name = name
    }
}

extension Practice: Content{}
extension Practice: Migration{}
extension Practice: Parameter{}


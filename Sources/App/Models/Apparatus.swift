//
//  Practice.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 29/10/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL



final class Apparatus: PostgreSQLUUIDModel {
    var id: UUID?
    var name: String
    var image: Data?

    init (name: String, image: Data) {
        self.name = name
        self.image = image
    }
}

extension Apparatus: Content {}
extension Apparatus: Migration {}
extension Apparatus: Parameter {}
extension Apparatus {
    var exercises: Children <Apparatus, Exercise> {
        return self.children(\.apparatusId)
    }
}


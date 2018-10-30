//
//  MeasureUnit.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 30/10/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class MeasureUnit: PostgreSQLUUIDModel {
    
    var id: UUID?
    var name: String
    
    init (name: String) {
        self.name = name
    }
    
}
extension MeasureUnit: Content {}
extension MeasureUnit: Migration {}
extension MeasureUnit: Parameter {}


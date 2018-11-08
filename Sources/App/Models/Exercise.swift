//
//  Exercise.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 30/10/2018.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Exercise: PostgreSQLUUIDModel {
    
    var id: UUID?
    var name: String
    var num_try: Int
    var apparatusId: Apparatus.ID
    var measure_unitId: MeasureUnit.ID
    var num_rep: Int
    var status: Bool
    var num_measure: Int
    
    public init (name: String, num_try: Int, apparatusId: Apparatus.ID, num_rep: Int, num_measure: Int, measure_unitId: MeasureUnit.ID) {
        
        self.name = name
        self.num_try = num_try
        self.apparatusId = apparatusId
        self.num_rep = num_rep
        self.num_measure = num_measure
        self.status = false
        self.measure_unitId = measure_unitId
    
    }
}

extension Exercise: Content{}
extension Exercise: Migration {
     public static func prepare(on connection: PostgreSQLConnection) -> Future<Void>{
        return Database.create(self, on: connection){builder in
            try addProperties(to: builder)
            builder.reference(from: \.apparatusId, to: \Apparatus.id)
            builder.reference(from: \.measure_unitId, to: \MeasureUnit.id)
        }
    }
    
}
extension Exercise: Parameter {}

extension Exercise {
    var apparatus : Parent <Exercise, Apparatus> {
        return parent(\.apparatusId)
    }
    var measure_unit : Parent <Exercise, MeasureUnit> {
        return parent(\.measure_unitId)
    }
}

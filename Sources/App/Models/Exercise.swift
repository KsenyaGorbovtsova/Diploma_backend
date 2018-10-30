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
    let apparatusId: Apparatus.ID
    let measure_unitId: MeasureUnit.ID
    var num_rep: Int
    var status: Bool
    var num_measure: Int
    
    public init (name: String, num_try: Int, apparatusId: Apparatus.ID, measure_unitId: MeasureUnit.ID,num_rep: Int, num_measure: Int) {
        
        self.name = name
        self.num_try = num_try
        self.num_rep = num_rep
        self.num_measure = num_measure
        self.status = false
        self.apparatusId = apparatusId
        self.measure_unitId = measure_unitId
    
    }
}

extension Exercise: Content{}
extension Exercise: Migration {}
extension Exercise: Parameter {}

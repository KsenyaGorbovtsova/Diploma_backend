//
//  MeasureUnitController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 30/10/2018.
//

import Foundation
import Vapor

final class MeasureUnitController {
    
    func index(_ req: Request) throws -> Future<[MeasureUnit]>{
        return MeasureUnit.query(on: req).all()
    }
    func create (_ req: Request) throws -> Future<MeasureUnit>{
        return try req.content.decode(MeasureUnit.self).flatMap {measureunit in
            return measureunit.save(on: req)
        }
    }
}

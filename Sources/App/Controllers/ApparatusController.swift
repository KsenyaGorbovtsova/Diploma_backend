//
//  ApparatusController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 29/10/2018.
//

import Foundation
import Vapor

final class ApparatusController {
    func index(_ req: Request) throws -> Future<[Apparatus]>{
        return Apparatus.query(on: req).all()
    }
    func create (_ req: Request) throws -> Future<Apparatus>{
        return try req.content.decode(Apparatus.self).flatMap {apparatus in
            return apparatus.save(on: req)
        }
    }
}

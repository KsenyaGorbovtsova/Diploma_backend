//
//  MeasureUnitController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 30/10/2018.
//

import Foundation
import Vapor
import Fluent
final class MeasureUnitController: RouteCollection {
    func boot(router: Router) throws {
        let units = router.grouped("measureunits")
        units.post(MeasureUnit.self, use: create)
        units.get(use: index)
        units.get(MeasureUnit.parameter, use: show)
        units.patch(MeasureUnitContent.self, at: MeasureUnit.parameter, use: update)
        units.delete(MeasureUnit.parameter, use: delete)
    }
    //--------выгрузить все-----------
    func index(_ req: Request) throws -> Future<[MeasureUnit]>{
        return MeasureUnit.query(on: req).all()
    }
    //--------создать запись-----------
    func create (_ req: Request, _ unit: MeasureUnit) throws -> Future<MeasureUnit>{
        return try req.content.decode(MeasureUnit.self).flatMap {measureunit in
            return measureunit.save(on: req)
        }
    }
    //--------выгрузить одну запись-----------
    func show (_ req: Request) throws -> Future<MeasureUnit> {
        return try req.parameters.next(MeasureUnit.self)
    }
    //--------обновить запись-----------
    func update (_ req: Request, _ body: MeasureUnitContent) throws -> Future<MeasureUnit> {
        let unit = try req.parameters.next(MeasureUnit.self)
        return unit.map(to: MeasureUnit.self, { unit in
            unit.id = body.id ?? unit.id
            unit.name = body.name ?? unit.name
            return unit
        }).update(on: req)
    }
    //--------удалить запись-----------
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(MeasureUnit.self).delete(on: req).transform(to: .noContent)
    }
    //-----структура для обновления-----
    struct MeasureUnitContent: Content {
        var id: UUID?
        var name: String?
    }
}

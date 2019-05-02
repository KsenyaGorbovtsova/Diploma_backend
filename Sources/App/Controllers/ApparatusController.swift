//
//  ApparatusController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 29/10/2018.
//

import Foundation
import Vapor
import Fluent

final class ApparatusController: RouteCollection{
    func boot(router: Router) throws {
        let apparatuses = router.grouped("apparatuses")
        apparatuses.post("create", use: create)
        apparatuses.get(use: index)
        apparatuses.get(Apparatus.parameter, use:show)
        apparatuses.patch(ApparatusContent.self, at: Apparatus.parameter, use: update)
        apparatuses.delete(Apparatus.parameter, use: delete)
    }
    //--------выгрузить все-----------
    func index(_ req: Request) throws -> Future<[Apparatus]>{
        return Apparatus.query(on: req).all()
    }
    //--------создать запись-----------
    func create (_ req: Request) throws -> Future<Apparatus>{
        return try req.content.decode(Apparatus.self).flatMap {apparatus in
            return apparatus.save(on: req)
        }
    }
    //--------выгрузить одну запись-----------
    func show (_ req: Request) throws -> Future <Apparatus> {
        return try req.parameters.next(Apparatus.self)
    }
    //--------обновить запись-----------
    func update(_ req: Request, _ body: ApparatusContent) throws -> Future<Apparatus>{
        let apparatus = try req.parameters.next(Apparatus.self)
        return apparatus.map(to: Apparatus.self, { apparatus in
            apparatus.id =  body.id ?? apparatus.id
            apparatus.name = body.name ?? apparatus.name
            apparatus.image = body.image ?? apparatus.image
            return apparatus
        }).update(on: req)
    }
    //--------удалить запись-----------
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Apparatus.self).delete(on: req).transform(to: .noContent)
    }
    //-----структура для обновления-----
    struct ApparatusContent: Content {
        var id: UUID?
        var name: String?
        var image: Data?
        
    }
}

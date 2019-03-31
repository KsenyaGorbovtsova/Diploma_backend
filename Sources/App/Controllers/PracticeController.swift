//
//  PracticeController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 15/11/2018.
//

import Foundation
import Vapor
import Fluent

final class PracticeController: RouteCollection{
    func boot(router: Router) throws {
        let practice = router.grouped("practices")
        practice.get(use: getPractices )
        practice.get(Practice.parameter, use: getOnePractice)
        practice.get(Practice.parameter, "contain", use: exercisesInPractice)
        practice.post(PracticeBody.self, use: create)
        practice.post( Practice.parameter,"addExercise", use: addExerciseToPractice)
        practice.delete(Practice.parameter, "delete", use: deleteExerciseFromPractice)
        practice.delete(Practice.parameter,"delete", use: delete)
        
    }
    ///----выгрузить все------
    func getPractices (_ req: Request) throws -> Future<[Practice]>{
        return Practice.query(on: req).all()
    }
    ///-----выгрузить одну тренировку------
    func getOnePractice (_ req: Request) throws -> Future<Practice>{
        return try req.parameters.next(Practice.self)
    }
    //---выгрузить упражнения, входящие в тренировку-------
    func exercisesInPractice (_ req: Request) throws -> Future<[Exercise]> {
        return try req.parameters.next(Practice.self).flatMap { exercise in
            return try exercise.containing.query(on: req).all()  ///!!!!!!!!
        }
    }
    //------создать тренировку----/
    func create (_ req: Request, body: PracticeBody) throws -> Future<Practice>{
        let practice = body.model()
        return practice.save(on: req)
    }
    //----добавить упражнения в тренировку
    func addExerciseToPractice(_ req: Request) throws -> Future <[String:Practice]> {
        let current = try req.parameters.next(Practice.self)
        let containingId  = req.content.get(Exercise.ID.self, at: "contain")
        let contain = containingId.and(result: req).flatMap(Exercise.find).unwrap( or: Abort(.badRequest, reason: "no such uid"))
        return flatMap (to: (current: Practice, containing: Exercise).self, current, contain) { current, contain in
            return current.addExercise(exercise: contain, on: req)
            }.map {practices -> [String: Practice] in
                return ["current":practices.current] //можно удалить но вдруг понадобится
        }
    }
    //------удалить упражнения из тренировки-----
    func deleteExerciseFromPractice(_ req: Request) throws -> Future<HTTPStatus> {
        let current = try req.parameters.next(Practice.self)
        let deletedID = req.content.get(Exercise.ID.self, at: "delete")
        let deleted = deletedID.and(result: req).flatMap(Exercise.find).unwrap(or: Abort(.badRequest, reason:"no uid"))
        return flatMap(to: HTTPStatus.self, current, deleted) {current, deleted in
            return current.deleteExercise(exercise: deleted, on: req).transform(to: .noContent)
        }
    }
    //----удалить тренировку ------
    func delete(_ req: Request) throws -> Future<HTTPStatus>{
        return try req.parameters.next(Practice.self).delete(on: req).transform(to: .noContent)
    }
    struct PracticeBody: Content {
        var status: Bool
        var name: String
        var owner: UUID
        func model() -> Practice {
            return Practice (status: self.status, name: self.name, owner: self.owner)
        }
    }
}

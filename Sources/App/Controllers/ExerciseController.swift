//
//  ExerciseController.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 30/10/2018.
//

import Foundation
import Vapor
import Fluent
import HTTP

/*final class ExerciseController: RouteCollection {
    func boot(router: Router) throws {
        let exercises = router.grouped("exercises", Exercise.parameter, "apparatuses")
    }
}
*/

final class ExerciseController: RouteCollection {
    func boot(router: Router) throws {
        let exercises = router.grouped("exercises")
        exercises.get("apparatus",Exercise.parameter,use: getApparatus)
        exercises.get(use: getExercises)
        exercises.get(Exercise.parameter, use: getOneExercise)
        exercises.post(  ExerciseBody.self, use: create )
        exercises.patch(ExerciseBody.self, at: Exercise.ID.parameter, use: update)
        exercises.delete(Exercise.parameter, use: delete)
    }
    //----получить снаряд по ключу упражнения-------
    func getApparatus (_ req: Request) throws -> Future<[Apparatus]> {
        return try req.parameters.next(Exercise.self).flatMap() { ex in
           try ex.apparatus.query(on: req).all()
       }
    }
    //----выгрузить все упражнения--------
    func getExercises (_ req: Request) throws -> Future<[Exercise]> {
            return Exercise.query(on: req).all()
        }
    //------выгрузить одно упражнение по ключу---------
    func getOneExercise (_ req: Request) throws -> Future<Exercise> {
        return try req.parameters.next(Exercise.self)
    }
    //------создать упражнение, передается ключ снаряда ---//
    func create(_ req: Request, body: ExerciseBody) throws -> Future<Exercise> {
        /*guard let value = req.parameters.rawValues(for: Apparatus.self).first,  let id = UUID(value) else {
            throw Abort(.badRequest, reason:"non convertible11")
        }*/
        let exercise = body.model()
        return exercise.save(on: req)
    }
    //-----изменить уражнение-----x костылище
    func update(_ req: Request, body: ExerciseBody) throws -> Future<Exercise> {
        let appId = body.apparatusId
        let app =  Apparatus.find(appId, on: req)
        /*if app == nil {
            throw Abort(.badRequest, reason: "apparatus with given id: \(appId) could not be found \(app)")
        }*/
       
       let id = try  req.parameters.next(Exercise.ID.self)
        let exercise = body.model()
        exercise.id  = id
        return exercise.update(on: req)
        
    }
    //----удалить упражнение ------
    func delete(_ req: Request) throws -> Future<HTTPStatus>{
        return try req.parameters.next(Exercise.self).delete(on: req).transform(to: .noContent)
    }
    
    struct ExerciseBody: Content {
        //var id: UUID
        var name: String
        var num_try: Int
        var num_rep: Int
        var status: Bool
        var num_measure: Int
        var apparatusId: UUID
        var measure_unitId: UUID
        
        func model() -> Exercise {
            return Exercise (name: self.name , num_try:self.num_try , apparatusId: self.apparatusId, num_rep: self.num_rep , num_measure: self.num_measure, measure_unitId: self.measure_unitId  )
        }
    }
 
}


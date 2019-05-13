//
//  ExercisePracticeConnection.swift
//  App
//
//  Created by Gorbovtsova Ksenya on 15/11/2018.
//

import Foundation
import FluentPostgreSQL
import Vapor

final class ExercisePracticeConnection: PostgreSQLPivot {
    
    var id: Int?
    
    static var leftIDKey: WritableKeyPath <ExercisePracticeConnection, UUID> = \.practiceId
    static var rightIDKey: WritableKeyPath <ExercisePracticeConnection, UUID> = \.exerciseId
    typealias Left = Practice
    typealias Right = Exercise
    
    var practiceId: UUID
    var exerciseId: UUID

    init (left: Practice, right: Exercise) throws {
        self.practiceId = try left.requireID()
        self.exerciseId = try right.requireID()
}

}
extension ExercisePracticeConnection: Migration{}
//extension ExercisePracticeConnection: Content{}
extension Practice {
    var containing: Siblings <Practice, Exercise, ExercisePracticeConnection> {
        return self.siblings(\ExercisePracticeConnection.practiceId, \ExercisePracticeConnection.exerciseId)
    }
    func addExercise (exercise: Exercise, on connection: DatabaseConnectable) -> Future<(current:Practice, containing: Exercise )>{
        return Future.flatMap(on: connection) {
            let pivot = try ExercisePracticeConnection(left: self, right: exercise)
            return pivot.save(on: connection).transform(to: (self, exercise))
        }
    }
    
    func deleteExercise (exercise: Exercise, on connection: DatabaseConnectable) -> Future<(current:Practice, deleted: Exercise)> {
        return self.containing.detach(exercise, on: connection).transform(to: (self, exercise))
    }
}

extension Practice {
    var exercises: Siblings<Practice, Exercise, ExercisePracticeConnection> {
        return siblings()
    }
}

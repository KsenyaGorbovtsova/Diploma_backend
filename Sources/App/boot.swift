import Foundation
import Vapor
import Fluent
import FluentSQL
/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    // your code here
    app.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: .hours(24)) { task in
        app.withPooledConnection(to: .psql) { conn -> Future<Void> in
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.dateFormat = "yyyy-MM-dd'T'00:00:00'Z'"
            let today = formatter.string(from: Date())
            let todayDate = formatter.date(from: today)
            let practices = Practice.query(on: conn).filter(\.date == todayDate).all()
            return practices.flatMap { practices -> Future<Void> in
                practices.map { practice in
                   let newPractice = Practice(status: practice.status ?? false, name: practice.name ?? "Без названия", owner: practice.owner, date: Calendar.current.date(byAdding: .day, value: practice.repeatAfter ?? 0, to: practice.date ?? Date.distantPast) ?? Date.distantPast, repeatAfter: practice.repeatAfter ?? 0)
                    let exercise = try! practice.containing.query(on: conn).all()
                    return exercise.flatMap { exercise -> Future<Void> in
                        exercise.map {
                            exr in
                            newPractice.addExercise(exercise: exr, on: conn).transform(to: Void())
                        }.transform(to: Void())
                        
                    }
                                       /* practice.date = Calendar.current.date(byAdding: .day, value: practice.repeatAfter, to: practice.date)*/
                    
                   return newPractice.save(on: conn).transform(to: Void())
                    }
                    .flatten(on: app)
                
            }
        }
    }
 
    
}


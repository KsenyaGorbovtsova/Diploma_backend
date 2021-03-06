import Foundation
import Vapor
import Fluent
import FluentSQL
/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    // your code here
    app.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: .hours(24)) { task in
        app.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: .hours(24)) { task in
            app.withPooledConnection(to: .psql) { conn -> Future<Void> in
                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.dateFormat = "yyyy-MM-dd'T'00:00:00'Z'"
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                let today = formatter.string(from: yesterday!)
                let todayDate = formatter.date(from: today)
                let practices = Practice.query(on: conn).filter(\.date == todayDate).all()
                
                return practices.flatMap { practices -> Future<Void> in
                    practices.map { practice in
                        practice.date = Calendar.current.date(byAdding: .day, value: practice.repeatAfter ?? 0, to: practice.date!)
                        return practice.update(on: conn).transform(to: ())
                        }
                        .flatten(on: app)
                    
                }
            }
        }
    }
}
    



import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    /*let apparatusController = ApparatusController()
    router.get("apparatuses", use: apparatusController.index)
    router.post("apparatuses", use: apparatusController.create)*/
    try router.register(collection: ApparatusController())
    try router.register(collection: MeasureUnitController())
    try router.register(collection: ExerciseController())
    try router.register(collection: PracticeController())
  
}

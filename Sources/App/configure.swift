import FluentPostgreSQL
import Vapor
import Authentication
/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
   /* let config = PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "GorbovtsovaKsenya", database: "fitness", password: nil, transport: .cleartext)
    let postgres = PostgreSQLDatabase(config: config)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: postgres, as: .psql)
    services.register(databases)
 */
//////
    var databases = DatabasesConfig()
    let databaseConfig: PostgreSQLDatabaseConfig
    if let url = Environment.get("DATABASE_URL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else if let url = Environment.get("DB_POSTGRESQL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else {
        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let username = Environment.get("DATABASE_USER") ?? "GorbovtsovaKsenya"
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        let databaseName: String
        let databasePort: Int
        if (env == .testing) {
            databaseName = "fitness"
            if let testPort = Environment.get("DATABASE_PORT") {
                databasePort = Int(testPort) ?? 5433
            } else {
                databasePort = 5433
            }
        } else {
            databaseName = Environment.get("DATABASE_DB") ?? "fitness"
            databasePort = 5432
        }
        
        databaseConfig = PostgreSQLDatabaseConfig(
            hostname: hostname,
            port: databasePort,
            username: username,
            database: databaseName,
            password: password)
    }
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Apparatus.self, database: .psql)
    migrations.add(model: MeasureUnit.self, database: .psql)
    migrations.add(model: Exercise.self, database: .psql)
    migrations.add(model: ExercisePracticeConnection.self, database:  .psql)
    migrations.add(model: Practice.self, database:  .psql)
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(model: UserPracticeConnection.self, database: .psql)
    //migrations.add(migration: AdminUser.self, database: .psql)
    services.register(migrations)
    
    var commands = CommandConfig.default()
    commands.useFluentCommands()
    services.register(commands)
    
    
  
    

}

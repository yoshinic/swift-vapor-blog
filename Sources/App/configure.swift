import Fluent
import FluentPostgresDriver
import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    app.http.server.configuration.port = 8081
    
    // uncomment to serve files from /Public folder
     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
    
    // Configure Leaf
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    
    // Password
    app.passwords.use(.bcrypt(cost: 15))
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Int(Environment.get("DATABASE_PORT") ?? "5432")!,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        ), as: .psql)
    
    app.migrations.add(CreateTag())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAdminUser())
    app.migrations.add(CreateBlog())
    app.migrations.add(CreateBlogTagPivot())
    app.migrations.add(CreateUserToken())
    // use fluent session
    app.sessions.use(.fluent)
    app.migrations.add(SessionRecord.migration)
    try app.autoMigrate().wait()
    
    // register routes
    try routes(app)
}

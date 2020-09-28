import Fluent
import FluentPostgresDriver
import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    app.http.server.configuration.port = Int(Environment.get("SERVER_PORT") ?? "8081")!
    app.routes.defaultMaxBodySize = .init(stringLiteral: Environment.get("DEFAULT_MAX_BODY_SIZE") ?? "10mb")
    
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
    
    // Configure Leaf
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    
    // Password
    app.passwords.use(.bcrypt(cost: 15))
    
    let config: DatabaseConfigurationFactory = try {
        guard
            let h = Environment.get("DATABASE_HOST"),
            let ps = Environment.get("DATABASE_PORT"), let p = Int(ps),
            let un = Environment.get("DATABASE_USERNAME"),
            let pw = Environment.get("DATABASE_PASSWORD"),
            let db = Environment.get("DATABASE_NAME")
        else { throw "DB情報を設定して下さい。" }
        return .postgres(hostname: h, port: p, username: un, password: pw, database: db)
    }()
    app.databases.use(config, as: .psql)
    
    app.migrations.add(CreateTag())
    app.migrations.add(CreateUser())
    if let n = Environment.get("USER_NAME"),
        let un = Environment.get("USER_USERNAME"),
        let p = Environment.get("USER_PASSWORD") {
        app.migrations.add(CreateAdminUser(n, un, p))
    }
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

extension Application {
    static let blogCountPerPage: Int = Int(Environment.get("BLOG_COUNT_PER_PAGE") ?? "9")!
}

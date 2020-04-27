import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("users", use: allUsersHandler)
        routes.get("register", use: registerHandler)
        routes.post("register", use: registerPostHandler)
    }
    
    func indexHandler(req: Request) throws -> EventLoopFuture<View> {
        req.view.render("index", IndexContext())
    }
    
    func allUsersHandler(_ req: Request) throws -> EventLoopFuture<View> {
        User
            .query(on: req.db)
            .all()
            .map { AllUsersContext(title: "ユーザー一覧", users: $0, userCounts: $0.count) }
            .flatMap { req.view.render("allUsers", $0) }
    }
    
    func registerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let context: RegisterContext = .init()
        return req.view.render("register", context)
    }
    
    func registerPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(RegisterPostData.self)
        
        let password = try Bcrypt.hash(data.password)
        let user = User(name: data.name, username: data.username, passwordHash: password)
        return user.save(on: req.db).map { user }.map { _ in req.redirect(to: "/") }
    }
}

struct IndexContext: Encodable {
    let title: String = "ブログトップ"
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
    let userCounts: Int
}

struct RegisterContext: Encodable {
    let title = "新規登録"
}

struct RegisterPostData: Decodable {
    let name: String
    let username: String
    let password: String
    let confirmPassword: String
}

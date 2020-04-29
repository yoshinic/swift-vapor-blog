import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authSessionRoutes = routes.grouped(UserSessionAuthenticator())
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("register", use: registerHandler)
        authSessionRoutes.post("register", use: registerPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("login", use: loginHandler)
        
        let protectedRoutes = authSessionRoutes.grouped(UserCredentialsAuthenticator())
        protectedRoutes.post("login", use: loginPostHandler)
    }
    
    func indexHandler(req: Request) throws -> EventLoopFuture<View> {
        let userLoggedIn = req.session.authenticated(User.self) != nil
        return req.view.render("index", IndexContext(userLoggedIn: userLoggedIn))
    }
    
    func allUsersHandler(_ req: Request) throws -> EventLoopFuture<View> {
        User
            .query(on: req.db)
            .all()
            .map { AllUsersContext(title: "ユーザー一覧", users: $0, userCounts: $0.count) }
            .flatMap { req.view.render("allUsers", $0) }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let hasError = req.query[Bool.self, at: "error"] ?? false
        let context: LoginContext = .init(loginError: hasError)
        return req.view.render("login", context)
    }
    
    func loginPostHandler(_ req: Request) throws -> Response {
        guard let user = req.auth.get(User.self) else {
            return req.redirect(to: "/login?error")
        }
        req.session.authenticate(user)
        return req.redirect(to: "/")
    }
    
    func logoutHandler(_ req: Request) throws -> Response {
        req.auth.logout(User.self)
        req.session.unauthenticate(User.self)
        return req.redirect(to: "/")
    }
    
    func registerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let context: RegisterContext = .init()
        return req.view.render("register", context)
    }
    
    func registerPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(RegisterPostData.self)
        return req.password.async.hash(data.password).flatMap { passwordHash in
            let user = User(name: data.name, username: data.username, passwordHash: passwordHash)
            return user.save(on: req.db).map { user }.map { _ in req.redirect(to: "/") }
        }
    }
}

struct IndexContext: Encodable {
    let title: String = "ブログトップ"
    let userLoggedIn: Bool
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
    let userCounts: Int
}

struct LoginContext: Encodable {
    let title = "ログイン"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginPostData: Decodable {
    let username: String
    let password: String
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

import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":\(FieldKey.userID.description)", use: getHandler)
        usersRoute.get(":\(FieldKey.userID.description)", "blogs", use: getBlogsHandler)
        
        let basicAuthGroup = usersRoute.grouped(
            User.authenticator(database: .psql),
            User.guardMiddleware()
        )
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthGroup = usersRoute.grouped(
            UserToken.authenticator(database: .psql),
            User.guardMiddleware()
        )
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":\(FieldKey.userID.description)", use: updateHandler)
        tokenAuthGroup.delete(":\(FieldKey.userID.description)", use: deleteHandler)
        tokenAuthGroup.post(":\(FieldKey.userID.description)", "restore", use: restoreHandler)
        tokenAuthGroup.delete(":\(FieldKey.userID.description)", "force", use: forceDeleteHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().map { $0.map{ $0.convertToPublic() } }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userID = req.parameters.get(FieldKey.userID.description, as: User.IDValue.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }
    
    func getBlogsHandler(_ req: Request) throws -> EventLoopFuture<[Blog]> {
        let userID = req.parameters.get(FieldKey.userID.description, as: User.IDValue.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$blogs.query(on: req.db).all() }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<UserToken> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        return token.save(on: req.db).map{ token }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        try User.Create.validate(content: req)
        let data = try req.content.decode(User.Create.self)
        return User
            .query(on: req.db)
            .filter(\.$username == data.username)
            .first()
            .guard({ $0 == nil }, else: Abort(.badRequest, reason: "そのユーザー名は既に登録されています。"))
            .flatMap { _ in req.password.async.hash(data.password) }
            .map { User(name: data.name, username: data.username, passwordHash: $0) }
            .flatMap { user in user.save(on: req.db).map { user }.convertToPublic() }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userID = req.parameters.get(FieldKey.userID.description, as: User.IDValue.self)
        let updateUserData = try req.content.decode(User.Create.self)
        return User
            .query(on: req.db)
            .filter(\.$id != userID!)
            .filter(\.$username == updateUserData.username)
            .first()
            .guard({ $0 != nil }, else: Abort(.badRequest, reason: "そのユーザー名は既に登録されています。"))
            .flatMap { _ in User.find(userID, on: req.db).unwrap(or: Abort(.notFound)) }
            .flatMap { user in
                req.password.async.hash(updateUserData.password).flatMap { passwordHash in
                    user.name = updateUserData.name
                    user.username = updateUserData.username
                    user.passwordHash = passwordHash
                    return user.save(on: req.db).map{ user }.convertToPublic()
                }
        }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let userID = req.parameters.get(FieldKey.userID.description, as: User.IDValue.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                return user.delete(on: req.db).transform(to: .ok)
        }
    }
    
    func restoreHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let userID = req.parameters.get(FieldKey.userID.description, as: User.IDValue.self)
        return User
            .query(on: req.db)
            .filter(\.$id == userID!)
            .withDeleted()
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { user -> EventLoopFuture<HTTPResponseStatus> in
                user.restore(on: req.db).transform(to: .ok)
        }
    }
    
    func forceDeleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        User
            .find(req.parameters.get(FieldKey.userID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user -> EventLoopFuture<HTTPResponseStatus> in
                return user.delete(force: true, on: req.db).transform(to: .ok)
        }
    }
}

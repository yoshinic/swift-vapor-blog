import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":user_id", use: getHandler)
        usersRoute.get(":user_id", "blogs", use: getBlogsHandler)
        usersRoute.post(use: createHandler)
        usersRoute.put(":user_id", use: updateHandler)
        usersRoute.delete(":user_id", use: deleteHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getBlogsHandler(_ req: Request) throws -> EventLoopFuture<[Blog]> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$blogs.query(on: req.db).all() }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let data = try req.content.decode(User.self)
        return User
            .query(on: req.db)
            .filter(\.$username == data.username)
            .first()
            .guard({ $0 == nil }, else: Abort(.badRequest, reason: "その username は既に存在します。"))
            .flatMap { _ in
                let user: User = .init(name: data.name,
                                       username: data.username,
                                       password: data.password)
                return user.save(on: req.db).map { user }
        }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        let updateUserData = try req.content.decode(User.self)
        let sameUsernameUser = User
            .query(on: req.db)
            .filter(\.$id != userID!)
            .filter(\.$username == updateUserData.username)
            .first()
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .and(value: updateUserData)
            .and(sameUsernameUser)
            .flatMapThrowing { v throws -> User in
                let ((user, updateData), sameUser) = v
                guard sameUser == nil else {
                    throw Abort(.badRequest, reason: "その username は既に存在します。")
                }
                user.name = updateData.name
                user.username = updateData.username
                user.password = updateData.password
                return user
        }
        .flatMap { user in
            user.save(on: req.db).map{ user }
        }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                return user.delete(on: req.db).transform(to: .ok)
        }
    }
}

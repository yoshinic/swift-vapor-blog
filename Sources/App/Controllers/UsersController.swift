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
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().map { $0.map{ $0.convertToPublic() } }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }
    
    func getBlogsHandler(_ req: Request) throws -> EventLoopFuture<[Blog]> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$blogs.query(on: req.db).all() }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let data = try req.content.decode(User.Create.self)
        return User
            .query(on: req.db)
            .filter(\.$username == data.username)
            .first()
            .guard({ $0 == nil }, else: Abort(.badRequest, reason: "その username は既に存在します。"))
            .flatMapThrowing { _ -> User in
                .init(name: data.name,
                      username: data.username,
                      passwordHash: try Bcrypt.hash(data.password))
                
        }
        .flatMap { user in
            return user.save(on: req.db).map { user }.convertToPublic()
        }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userID = req.parameters.get("user_id", as: UUID.self)
        let updateUserData = try req.content.decode(User.Create.self)
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
                user.passwordHash = try Bcrypt.hash(updateData.password)
                return user
        }
        .flatMap { user in
            user.save(on: req.db).map{ user }.convertToPublic()
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

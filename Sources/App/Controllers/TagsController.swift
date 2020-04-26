import Vapor
import Fluent

struct TagsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tagsRoute = routes.grouped("api", "tags")
        tagsRoute.get(use: getAllHandler)
        tagsRoute.get(":tag_id", use: getHandler)
        tagsRoute.get(":tag_id", "blogs", use: getBlogsHandler)
        
        let tokenAuthGroup = tagsRoute.grouped(
            UserToken.authenticator(database: .psql),
            User.guardMiddleware()
        )
        tokenAuthGroup.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Tag]> {
        Tag.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Tag> {
        Tag
            .find(req.parameters.get("tag_id"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getBlogsHandler(_ req: Request) throws -> EventLoopFuture<[Blog]> {
        Tag
            .find(req.parameters.get("tag_id"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$blogs.query(on: req.db).all() }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Tag> {
        let tag = try req.content.decode(Tag.self)
        return tag.save(on: req.db).map{ tag }
    }
}

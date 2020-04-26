import Vapor
import Fluent

struct BlogsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let blogsRoutes = routes.grouped("api", "blogs")
        blogsRoutes.get(use: getAllHandler)
        blogsRoutes.get(":blog_id", use: getHandler)
        blogsRoutes.get(":blog_id", "user", use: getUserHandler)
        blogsRoutes.post(use: createHandler)
        blogsRoutes.put(":blog_id", use: updateHandler)
        blogsRoutes.delete(":blog_id", use: deleteHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Blog]> {
        Blog.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Blog> {
        Blog
            .find(req.parameters.get("blog_id"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getUserHandler(_ req: Request) throws -> EventLoopFuture<User> {
        Blog
            .find(req.parameters.get("blog_id"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$user.get(on: req.db) }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Blog> {
        let data = try req.content.decode(Blog.self)
        let blog = Blog(title: data.title, contents: data.contents, userID: data.$user.id)
        return blog.save(on: req.db).map{ blog }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Blog> {
        let blogID = req.parameters.get("blog_id", as: UUID.self)
        let updateBlogData = try req.content.decode(Blog.self)
        return Blog
            .find(blogID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .and(value: updateBlogData)
            .flatMapThrowing { blog, updateData throws -> Blog in
                blog.title = updateData.title
                blog.contents = updateData.contents
                blog.$user.id = updateData.$user.id
                return blog
        }
        .flatMap { blog in
            return blog.save(on: req.db).map{ blog }
        }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let blogID = req.parameters.get("blog_id", as: UUID.self)
        return Blog
            .find(blogID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { blog -> EventLoopFuture<HTTPResponseStatus> in
                blog.delete(on: req.db).transform(to: .ok)
        }
    }
}

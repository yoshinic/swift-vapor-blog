import Vapor
import Fluent

struct BlogsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let blogsRoutes = routes.grouped("api", "blogs")
        blogsRoutes.get(use: getAllHandler)
        blogsRoutes.get(":\(FieldKey.blogID.description)", use: getHandler)
        blogsRoutes.get(":\(FieldKey.blogID.description)", "user", use: getUserHandler)
        blogsRoutes.get(":\(FieldKey.blogID.description)", "tags", use: getTagsHandler)
        
        let tokenAuthGroup = blogsRoutes.grouped(
            UserToken.authenticator(database: .psql),
            User.guardMiddleware()
        )
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":\(FieldKey.blogID.description)", use: updateHandler)
        tokenAuthGroup.delete(":\(FieldKey.blogID.description)", use: deleteHandler)
        tokenAuthGroup.post(":\(FieldKey.blogID.description)", "tags", ":\(FieldKey.tagID.description)", use: addTagsHandler)
        tokenAuthGroup.delete(":\(FieldKey.blogID.description)", "tags", ":\(FieldKey.tagID.description)", use: removeTagsHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Blog]> {
        Blog.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Blog> {
        Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getUserHandler(_ req: Request) throws -> EventLoopFuture<User> {
        Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.$user.get(on: req.db) }
    }
    
    func getTagsHandler(_ req: Request) throws -> EventLoopFuture<[Tag]> {
        Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { blog -> EventLoopFuture<[Tag]> in
                blog.$tags.query(on: req.db).all()
        }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Blog> {
        let data = try req.content.decode(Blog.self)
        let blog: Blog = .init(pictureBase64: data.pictureBase64 ?? "",
                               title: data.title,
                               contents: data.contents,
                               userID: data.$user.id)
        return blog.save(on: req.db).map{ blog }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Blog> {
        let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self)
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
        Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { blog -> EventLoopFuture<HTTPResponseStatus> in
                blog.delete(on: req.db).transform(to: .ok)
        }
    }
    
    func addTagsHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let blog = Blog.find(req.parameters.get(FieldKey.blogID.description), on: req.db).unwrap(or: Abort(.notFound))
        let tag = Tag.find(req.parameters.get(FieldKey.tagID.description), on: req.db).unwrap(or: Abort(.notFound))
        return blog
            .and(tag)
            .flatMap { (blog, tag) -> EventLoopFuture<HTTPResponseStatus> in
                blog.$tags.attach(tag, on: req.db).transform(to: .created)
        }
    }
    
    func removeTagsHandler(_ req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
        let blog = Blog.find(req.parameters.get(FieldKey.blogID.description), on: req.db).unwrap(or: Abort(.notFound))
        let tag = Tag.find(req.parameters.get(FieldKey.tagID.description), on: req.db).unwrap(or: Abort(.notFound))
        return blog
            .and(tag)
            .flatMap { (blog, tag) -> EventLoopFuture<HTTPResponseStatus> in
                blog.$tags.detach(tag, on: req.db).transform(to: .noContent)
        }
    }
}

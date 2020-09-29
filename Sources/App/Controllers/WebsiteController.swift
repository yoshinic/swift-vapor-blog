import Vapor
import Fluent
import SwiftGD

struct WebsiteController: RouteCollection {
    
    private let tokenIdentifier = "CSRF_TOKEN"
    
    // short column の最大文字列数
    private let shortMaxLength: Int = 100
    
    func boot(routes: RoutesBuilder) throws {
        let authSessionRoutes = routes.grouped(UserSessionAuthenticator())
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get(":page", ":per", use: indexPageHandler)
        authSessionRoutes.get(
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            use: blogHandler
        )
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.on(
            .GET,
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            "picture",
            body: .stream,
            use: getPictureHandler
        )
        authSessionRoutes.on(
            .GET,
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            "contents",
            body: .stream,
            use: getContentsHandler
        )
        authSessionRoutes.on(
            .GET,
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            "image",
            ":idx",
            body: .stream,
            use: getContentsPictureHandler
        )
        
        let protectedRoutes = authSessionRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.get("blogs", "create", use: createBlogHandler)
        protectedRoutes.post("blogs", "create", use: createBlogPostHandler)
        protectedRoutes.get(
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            "edit",
            use: editBlogHandler
        )
        protectedRoutes.post(
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            "edit",
            use: editBlogPostHandler
        )
        protectedRoutes.post(
            "blogs",
            ":\(FieldKey.groupID.description)",
            ":\(FieldKey.blogID.description)",
            "delete",
            use: deleteBlogHandler
        )
        
        let passwordProtected = authSessionRoutes.grouped(UserCredentialsAuthenticator())
        passwordProtected.post("login", use: loginPostHandler)
    }
    
    private func _indexHandler(page: Int, per: Int, on req: Request) -> EventLoopFuture<View> {
        Blog
            .query(on: req.db)
            .filter(\.$latest == true)
            .field(\.$id)
            .field(\.$groupID)
            .field(\.$comment)
            .field(\.$picture)
            .field(\.$title)
            .with(\.$tags)
            .with(\.$contents)
            .sort(\.$updatedAt, .descending)
            .paginate(.init(page: page, per: per))
            .map { (pageBlogs: Page<Blog>) in
                IndexContext(
                    userLoggedIn: req.session.authenticated(User.self) != nil,
                    blogs: pageBlogs.items.enumerated().map { (i: Int, blog: Blog) in
                        .init(
                            idx: i,
                            id: blog.id!.uuidString,
                            groupID: blog.groupID.uuidString,
                            picturePath: "",
                            title: blog.title,
                            tags: blog.tags.map { $0.name },
                            short: blog.contents.short(self.shortMaxLength)
                        )
                    },
                    metadata: pageBlogs.metadata
                )
            }
            .flatMap { req.view.render("index", $0) }
    }
    
    func indexHandler(req: Request) throws -> EventLoopFuture<View> {
        _indexHandler(page: 1, per: Application.blogCountPerPage, on: req)
    }
    
    func indexPageHandler(req: Request) throws -> EventLoopFuture<View> {
        guard
            let page = req.parameters.get("page", as: Int.self),
            let per = req.parameters.get("per", as: Int.self)
            else { throw Abort(.notFound) }
        return _indexHandler(page: page, per: per, on: req)
    }
    
    func allUsersHandler(_ req: Request) throws -> EventLoopFuture<View> {
        User
            .query(on: req.db)
            .all()
            .map { AllUsersContext(title: "ユーザー一覧", users: $0, userCounts: $0.count) }
            .flatMap { req.view.render("allUsers", $0) }
    }
    
    func userHandler(_ req: Request) throws -> EventLoopFuture<View> {
        User
            .find(req.parameters.get("user_id"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$blogs.get(on: req.db).flatMap { (blogs: [Blog]) in
                    let context: UserContext = .init(user: user, blogs: blogs)
                    return req.view.render("user", context)
                }
        }
    }
    
    func blogHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard
            let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self)
        else {
            throw Abort(.notFound)
        }
        return Blog
            .query(on: req.db)
            .filter(\.$id == blogID)
            .with(\.$user)
            .with(\.$tags)
            .first()
            .unwrap(or: Abort(.notFound))
            .and(value: req.auth.get(User.self))
            .flatMapThrowing {
                let (blog, authenticatedUser) = $0
                if let d = blog.picture, d.count >= 1_000_000 {
                    blog.picture = try Image(data: d, as: .png).resizedTo(height: 100, applySmoothing: true)?.export()
                }
                return (blog, authenticatedUser)
        }
        .flatMap { (blog: Blog, authenticatedUser: User?) in
            let context: BlogContext = .init(title: blog.title,
                                             blog: blog,
                                             authenticatedUser: authenticatedUser)
            return req.view.render("blog", context)
        }
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
    
    func createBlogHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let token = [UInt8].random(count: 16).base64
        let context = CreateBlogContext(csrfToken: token)
        req.session.data[tokenIdentifier] = token
        return req.view.render("createBlog", context)
    }
    
    func createBlogPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreateBlogData.self)
        let expectedToken = req.session.data[tokenIdentifier]
        req.session.data[tokenIdentifier] = nil
        guard let csrfToken = data.csrfToken, expectedToken == csrfToken
        else { throw Abort(.badRequest) }
        
        return Blog
            .add(
                try convertPictureData(data.picture),
                data.title,
                try req.auth.require(User.self).requireID(),
                data.contents,
                data.tags,
                on: req.db(.psql)
            )
            .map { req.redirect(to: "/blogs/\($0.groupID)/\($0.id!)") }
    }
    
    func getPictureHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self) else {
            return req.eventLoop.future(.init(status: .notFound))
        }
        return Blog
            .query(on: req.db)
            .field(\.$picture)
            .filter(\.$id == blogID)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { $0.picture }
            .map { .init(status: .ok, body: .init(data: $0 ?? .init())) }
    }
    
    func getContentsPictureHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard
            let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self),
            let order = req.parameters.get("idx", as: Int.self)
            else { return req.eventLoop.future(.init(status: .notFound)) }
        return BlogContent
            .query(on: req.db)
            .field(\.$data)
            .filter(\.$blog.$id == blogID)
            .filter(\.$order == order)
            .first()
            .map { content in
                guard let content = content else { return .init(status: .notFound) }
                return .init(status: .ok, body: .init(data: content.data ?? .init()))
        }
    }
    
    func getContentsHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard
            let groupID = req.parameters.get(FieldKey.groupID.description, as: UUID.self),
            let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self)
        else {
            return req.eventLoop.future(.init(status: .notFound))
        }
        return BlogContent
            .query(on: req.db)
            .field(\.$id)
            .field(\.$order)
            .field(\.$type)
            .field(\.$attributes)
            .field(\.$text)
            .field(\.$data)
            .filter(\.$blog.$id == blogID)
            .sort(\.$order, .ascending)
            .all()
            .flatMapThrowing { try $0.string(groupID, blogID)?.data(using: .utf8) ?? .init() }
            .map { .init(status: .ok, body: .init(data: $0)) }
    }
    
    func editBlogHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard
            let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self)
        else {
            throw Abort(.notFound)
        }
        return Blog
            .query(on: req.db)
            .filter(\.$id == blogID)
            .with(\.$tags)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { req.view.render("createBlog", EditBlogContext(blog: $0))
        }
    }
    
    func editBlogPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard
            let groupID = req.parameters.get(FieldKey.groupID.description, as: UUID.self),
            let blogID = req.parameters.get(FieldKey.blogID.description, as: Blog.IDValue.self)
        else {
            return req.eventLoop.future(.init(status: .notFound))
        }
        let d = try req.content.decode(CreateBlogData.self)
        
        return Blog
            .update(
                groupID,
                blogID,
                try req.auth.require(User.self).id!,
                d.comment,
                try convertPictureData(d.picture),
                d.updatingPicture,
                d.title,
                d.contents,
                d.tags,
                on: req.db(.psql)
            )
            .map { req.redirect(to: "/blogs/\($0.groupID)/\($0.id!)") }
    }
    
    func deleteBlogHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard
            let groupID = req.parameters.get(FieldKey.groupID.description, as: UUID.self)
        else {
            return req.eventLoop.future(.init(status: .notFound))
        }
        return req.db.transaction { db in
            Blog
                .query(on: db)
                .field(\.$id)
                .filter(\.$groupID == groupID)
                .all()
                .flatMapEach(on: db.eventLoop) { $0.delete(on: db) }
        }
        .map { _ in req.redirect(to: "/") }
    }
}

private extension WebsiteController {
    func convertPictureData(_ pictureData: String?) throws -> Data? {
        guard
            let d = pictureData?.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: d) as? [String: Any],
            let base64Format = json["data"] as? String
        else {
            return nil
        }
        let comp = base64Format.components(separatedBy: ",")
        guard comp.count == 2 else { return nil }
        return Data(base64Encoded: comp[1])
    }
}

struct IndexPageBlogContext: Encodable {
    let idx: Int
    let id: String
    let groupID: String
    let picturePath: String?
    let title: String
    let tags: [String]?
    let short: String?
}

struct IndexContext: Encodable {
    let title: String = "ブログトップ"
    let userLoggedIn: Bool
    let blogs: [IndexPageBlogContext]
    let metadata: PageMetadata
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
    let userCounts: Int
}

struct UserContext: Encodable {
    let title: String = "ユーザー情報"
    let user: User
    let blogs: [Blog]
}

struct BlogContext: Encodable {
    let title: String
    let blog: Blog
    let authenticatedUser: User?
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

struct CreateBlogContext: Encodable {
    let title = "ブログ作成"
    let csrfToken: String
}

struct CreateBlogData: Decodable {
    let comment: String?
    let picture: String?
    let updatingPicture: Bool
    let title: String
    let contents: String?
    let tags: String?
    let csrfToken: String?
}

struct EditBlogContext: Encodable {
    let title = "ブログ編集"
    let blog: Blog
    let editing = true
}

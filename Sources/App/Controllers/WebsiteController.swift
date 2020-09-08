import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    
    private let tokenIdentifier = "CSRF_TOKEN"
    
    func boot(routes: RoutesBuilder) throws {
        let authSessionRoutes = routes.grouped(UserSessionAuthenticator())
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("users", ":\(FieldKey.userID.description)", use: userHandler)
        authSessionRoutes.get("blogs", ":\(FieldKey.blogID.description)", use: blogHandler)
        authSessionRoutes.get("register", use: registerHandler)
        authSessionRoutes.post("register", use: registerPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("login", use: loginHandler)
        
        let protectedRoutes = authSessionRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.get("blogs", "create", use: createBlogHandler)
        protectedRoutes.post("blogs", "create", use: createBlogPostHandler)
        protectedRoutes.get("blogs", ":\(FieldKey.blogID.description)", "edit", use: editBlogHandler)
        protectedRoutes.post("blogs", ":\(FieldKey.blogID.description)", "edit", use: editBlogPostHandler)
        protectedRoutes.post("blogs", ":\(FieldKey.blogID.description)", "delete", use: deleteBlogHandler)
        
        let passwordProtected = authSessionRoutes.grouped(UserCredentialsAuthenticator())
        passwordProtected.post("login", use: loginPostHandler)
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
        Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { blog in
                blog
                    .$user
                    .get(on: req.db)
                    .and(blog.$tags.query(on: req.db).all())
                    .and(value: req.auth.get(User.self))
                    .flatMap {
                        let ((user, tags), authenticatedUser) = $0
                        let context: BlogContext = .init(title: blog.title,
                                                         blog: blog,
                                                         user: user,
                                                         tags: tags,
                                                         authenticatedUser: authenticatedUser)
                        return req.view.render("blog", context)
                }
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
        guard let csrfToken = data.csrfToken, expectedToken == csrfToken else {
            throw Abort(.badRequest)
        }
        let userLoggedIn = try req.auth.require(User.self)
        let blog = Blog(pictureBase64: data.pictureBase64,
                        title: data.title,
                        contents: data.contents,
                        userID: try userLoggedIn.requireID())
        return blog
            .save(on: req.db)
            .map{ blog }
            .flatMapThrowing { savedBlog in
                guard let savedBlogId = savedBlog.id else { throw Abort(.internalServerError) }
                var tagSaves: [EventLoopFuture<Void>] = []
                for tag in data.tags ?? [] {
                    tagSaves.append(
                        Tag.addTag(tag, to: savedBlog, on: req))
                }
                return (tagSaves, savedBlogId)
        }
        .flatMap { (tagSaves: [EventLoopFuture<Void>], savedBlogId: Blog.IDValue) -> EventLoopFuture<Response> in
            let redirect = req.redirect(to: "/blogs/\(savedBlogId)")
            return tagSaves.flatten(on: req.eventLoop).transform(to: redirect)
        }
    }
    
    func editBlogHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .and(value: req.auth.get(User.self))
            .flatMap { (blog: Blog, user: User?) in
                blog.$tags.query(on: req.db).all().flatMap { tags in
                    let context: EditBlogContext = .init(blog: blog, tags: tags)
                    return req.view.render("createBlog", context)
                }
        }
    }
    
    func editBlogPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        return Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .and(value: try req.content.decode(CreateBlogData.self))
            .and(value: try req.auth.require(User.self))
            .flatMap {
                let ((blog, createBlogData), user) = $0
                blog.title = createBlogData.title
                blog.contents = createBlogData.contents
                blog.$user.id = user.id!
                
                return blog.save(on: req.db).map { blog }.flatMap { blog in
                    blog.$tags.query(on: req.db).all()
                        .flatMap { (existingTags: [Tag]) -> EventLoopFuture<Response> in
                            let existingSet = Set<String>(existingTags.map { $0.name })
                            let newSet = Set<String>(createBlogData.tags ?? [])
                            let tagsToAdd = newSet.subtracting(existingSet)
                            let tagsToRemove = existingSet.subtracting(newSet)
                            var tagResults: [EventLoopFuture<Void>] = []
                            tagsToAdd.forEach { newTag in
                                tagResults.append(Tag.addTag(newTag, to: blog, on: req))
                            }
                            tagsToRemove.forEach { tagNameToRemove in
                                let tagToRemove = existingTags.first { $0.name == tagNameToRemove }
                                if let tag = tagToRemove {
                                    tagResults.append(blog.$tags.detach(tag, on: req.db))
                                }
                            }
                            
                            let redirect = req.redirect(to: "/blogs/\(blog.id!)")
                            return tagResults.flatten(on: req.eventLoop).transform(to: redirect)
                    }
                }
        }
    }
    
    func deleteBlogHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        Blog
            .find(req.parameters.get(FieldKey.blogID.description), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { blog in
                blog.$tags
                    .get(reload: true, on: req.db)
                    .flatMap { blog.$tags.detach($0, on: req.db) }
                    .flatMap { blog.delete(on: req.db) }
                    .and(value: req.auth.get(User.self))
                    .map { req.redirect(to: "/users/\($0.1!.id!)") }
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

struct UserContext: Encodable {
    let title: String = "ユーザー情報"
    let user: User
    let blogs: [Blog]
}

struct BlogContext: Encodable {
    let title: String
    let blog: Blog
    let user: User
    let tags: [Tag]?
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
    let pictureBase64: String?
    let title: String
    let contents: String
    let tags: [String]?
    let csrfToken: String?
}

struct EditBlogContext: Encodable {
    let title = "ブログ編集"
    let blog: Blog
    let editing = true
    let tags: [Tag]?
}

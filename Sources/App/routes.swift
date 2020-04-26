import Fluent
import Vapor

func routes(_ app: Application) throws {
    let blogsController: BlogsController = .init()
    try app.register(collection: blogsController)
    
    let usersController: UsersController = .init()
    try app.register(collection: usersController)
    
    let tagsController: TagsController = .init()
    try app.register(collection: tagsController)
    
    let websiteController: WebsiteController = .init()
    try app.register(collection: websiteController)
}

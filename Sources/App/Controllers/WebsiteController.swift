import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
    }
    
    func indexHandler(req: Request) throws -> EventLoopFuture<View> {
        req.view.render("index", ["title": "Hi", "body": "Hello world!"])
    }
}

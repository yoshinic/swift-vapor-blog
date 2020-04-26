@testable import App
import Vapor
import FluentPostgresDriver

extension Blog {
    static func create(
        title: String = "タイトル",
        contents: String? = nil,
        on db: Database
    ) throws -> Blog {
        let blog = Blog(
            title: title,
            contents: contents
        )
        return try blog.save(on: db).map { blog }.wait()
    }
}

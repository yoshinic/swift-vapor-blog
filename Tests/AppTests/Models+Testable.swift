@testable import App
import Vapor
import FluentPostgresDriver

extension Blog {
    static func create(
        title: String = "デフォルトタイトル",
        contents: String? = nil,
        user: User? = nil,
        on db: Database
    ) throws -> Blog {
        var blogsUser = user
        if blogsUser == nil {
            blogsUser = try User.create(on: db)
        }
        let blog = Blog(
            title: title,
            contents: contents,
            userID: blogsUser!.id!
        )
        return try blog.save(on: db).map { blog }.wait()
    }
}

extension User {
    static func create(
        name: String = "デフォルト名",
        username: String? = nil,
        on db: Database
    ) throws -> User {
        let createUsername: String
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            createUsername = UUID().uuidString
        }
        let user = User(name: name, username: createUsername, password: "password")
        return try user.save(on: db).map { user }.wait()
    }
}

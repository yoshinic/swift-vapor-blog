@testable import App
import Vapor
import FluentPostgresDriver

extension Blog {
    static func create(
        picture: Data? = nil,
        title: String = "デフォルトタイトル",
        user: User? = nil,
        on db: Database
    ) throws -> Blog {
        var blogsUser = user
        if blogsUser == nil {
            blogsUser = try User.create(on: db)
        }
        
        let blog = Blog(
            picture: picture,
            title: title,
            userID: blogsUser!.id!
        )
        return try blog.save(on: db).map { blog }.wait()
    }
}

extension User {
    static func create(
        name: String = "デフォルト名",
        username: String? = nil,
        password: String = "password",
        on db: Database
    ) throws -> User {
        let createUsername: String
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            createUsername = UUID().uuidString
        }
        let passwordHash = try Bcrypt.hash(password)
        let user = User(name: name, username: createUsername, passwordHash: passwordHash)
        return try user.save(on: db).map { user }.wait()
    }
}

extension Tag {
    static func create(
        name: String? = nil,
        on db: Database
    ) throws -> Tag {
        let createTagName: String
        if let suppliedUsername = name {
            createTagName = suppliedUsername
        } else {
            createTagName = UUID().uuidString
        }
        let tag = Tag(name: createTagName)
        return try tag.save(on: db).map { tag }.wait()
    }
}

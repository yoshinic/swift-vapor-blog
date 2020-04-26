import Vapor
import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string)
            .field("username", .string, .required)
            .field("password_hash", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}

struct CreateAdminUser: Migration {
    let adminUsername = "admin"
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let password = try? Bcrypt.hash("password")
        guard let hashedPassword = password else { fatalError("Failed to create admin user") }
        let user: User = .init(name: "Admin",
                               username: adminUsername,
                               passwordHash: hashedPassword)
        return user.save(on: database).transform(to: ())
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User
            .query(on: database)
            .filter(\.$username == adminUsername)
            .delete(force: true)
    }
}

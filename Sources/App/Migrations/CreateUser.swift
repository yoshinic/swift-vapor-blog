import Vapor
import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field(.name, .string)
            .field(.username, .string, .required)
            .field(.passwordHash, .string)
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}

struct CreateAdminUser: Migration {
    private let _name: String
    private let _username: String
    private let _password: String
    
    init(
        _ name: String,
        _ username: String,
        _ password: String
    ) {
        self._name = name
        self._username = username
        self._password = password
    }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let password = try? Bcrypt.hash(_password)
        guard let hashedPassword = password else { fatalError("管理者ユーザーを設定できませんでした。") }
        let user: User =  .init(name: _name, username: _username, passwordHash: hashedPassword)
        return user.save(on: database).transform(to: ())
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User
            .query(on: database)
            .filter(\.$username == _username)
            .delete(force: true)
    }
}

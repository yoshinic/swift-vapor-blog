import Fluent

struct CreateUserToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserToken.schema)
            .id()
            .field(.value, .string, .required, .sql(.unique))
            .field(.userID, .uuid, .references(User.schema, .id))
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserToken.schema).delete()
    }
}

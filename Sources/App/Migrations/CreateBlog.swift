import Fluent

struct CreateBlog: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Blog.schema)
            .id()
            .field(.groupID, .uuid, .required)
            .field(.version, .int, .required, .sql(.default(1)))
            .field(.comment, .string, .sql(.default("")))
            .field(.latest, .bool, .required)
            .field(.picture, .data)
            .field(.title, .string, .required)
            .field(.userID, .uuid, .references(User.schema, .id))
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Blog.schema).delete()
    }
}

import Fluent

struct CreateBlog: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Blog.schema)
            .id()
            .field(.pictureBase64, .string)
            .field(.title, .string, .required)
            .field(.contents, .string)
            .field(.userID, .uuid, .references(User.schema, .id))
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Blog.schema).delete()
    }
}

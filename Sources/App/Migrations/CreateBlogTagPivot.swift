import Fluent

struct CreateBlogTagPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlogTagPivot.schema)
            .id()
            .field(.blogID, .uuid, .required, .references(Blog.schema, .id))
            .field(.tagID, .uuid, .required, .references(Tag.schema, .id))
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlogTagPivot.schema).delete()
    }
}


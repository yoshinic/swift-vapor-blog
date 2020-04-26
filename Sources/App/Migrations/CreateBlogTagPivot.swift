import Fluent

struct CreateBlogTagPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlogTagPivot.schema)
            .id()
            .field("blog_id", .uuid, .required, .references(Blog.schema, .id))
            .field("tag_id", .uuid, .required, .references(Tag.schema, .id))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlogTagPivot.schema).delete()
    }
}


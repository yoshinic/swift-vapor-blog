import Fluent

struct CreateBlogContent: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        BlogContentAttribute.AlignType.create(on: database).flatMap { _ in
            BlogContentAttribute.DirectionType.create(on: database).flatMap { _ in
                BlogContentAttribute.ListType.create(on: database).flatMap { _ in
                    BlogContentAttribute.ScriptType.create(on: database).flatMap { _ in
                        BlogContent.ContentType.create(on: database).flatMap { type in
                            database
                                .schema(BlogContent.schema)
                                .id()
                                .field(.order, .int, .required)
                                .field(.type, type, .required)
                                .field(.attributes, .json, .required)
                                .field(.text, .string, .required)
                                .field(.data, .data)
                                .field(.blogID, .uuid, .required)
                                .field(.createdAt, .datetime)
                                .field(.updatedAt, .datetime)
                                .field(.deletedAt, .datetime)
                                .create()
                        }
                    }
                }
            }
        }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(BlogContent.schema).delete().flatMap {
            database.enum(BlogContent.ContentType.name).delete().flatMap {
                database.enum(BlogContentAttribute.AlignType.name).delete().flatMap {
                    database.enum(BlogContentAttribute.DirectionType.name).delete().flatMap {
                        database.enum(BlogContentAttribute.ListType.name).delete().flatMap {
                            database.enum(BlogContentAttribute.ScriptType.name).delete().transform(to: ())
                        }
                    }
                }
            }
        }
    }
}

import Fluent

struct CreateTag: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Tag.schema)
            .id()
            .field(.name, .string, .required, .sql(.unique))
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Tag.schema).delete()
    }
}


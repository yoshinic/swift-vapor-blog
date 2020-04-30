import Vapor
import Fluent

final class Tag: Model, Content {
    static var schema: String = "tags"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: BlogTagPivot.self, from: \.$tag, to: \.$blog)
    var blogs: [Blog]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: Tag.IDValue? = nil,
         name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag {
    static func addTag(_ name: String, to blog: Blog, on req: Request) -> EventLoopFuture<Void> {
        return Tag
            .query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundTag in
                if let existingTag = foundTag {
                    return blog.$tags.attach(existingTag, on: req.db).transform(to: ())
                } else {
                    let tag = Tag(name: name)
                    return tag.save(on: req.db).map { tag }.flatMap { savedTag in
                        return blog.$tags.attach(savedTag, on: req.db).transform(to: ())
                    }
                }
        }
    }
}


import Vapor
import Fluent

final class BlogTagPivot: Model {
    static let schema = "blog_tag_pivot"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "blog_id")
    var blog: Blog
    
    @Parent(key: "tag_id")
    var tag: Tag
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: BlogTagPivot.IDValue? = nil,
         _ blogID: Int,
         _ tagID: Int) throws {
        self.id = id
        self.$blog.id = try blog.requireID()
        self.$tag.id = try tag.requireID()
    }
}


import Vapor
import Fluent

final class Blog: Model, Content {
    
    static let schema = "blogs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "contents")
    var contents: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: Blog.IDValue? = nil,
        title: String,
        contents: String?
    ) {
        self.id = id
        self.title = title
        self.contents = contents
    }
}

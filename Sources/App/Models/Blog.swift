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
    
    @Parent(key: "user_id")
    var user: User
    
    @Siblings(through: BlogTagPivot.self, from: \.$blog, to: \.$tag)
    var tags: [Tag]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: Blog.IDValue? = nil,
        title: String,
        contents: String?,
        userID: User.IDValue
    ) {
        self.id = id
        self.title = title
        self.contents = contents
        self.$user.id = userID
    }
}

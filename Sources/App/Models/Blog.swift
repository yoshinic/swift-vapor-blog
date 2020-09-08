import Vapor
import Fluent

final class Blog: Model, Content {
    
    static let schema = "blogs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: .pictureBase64)
    var pictureBase64: String?
    
    @Field(key: .title)
    var title: String
    
    @Field(key: .contents)
    var contents: String?
    
    @Parent(key: .userID)
    var user: User
    
    @Siblings(through: BlogTagPivot.self, from: \.$blog, to: \.$tag)
    var tags: [Tag]
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: Blog.IDValue? = nil,
        pictureBase64: String?,
        title: String,
        contents: String?,
        userID: User.IDValue
    ) {
        self.id = id
        self.pictureBase64 = pictureBase64
        self.title = title
        self.contents = contents
        self.$user.id = userID
    }
}

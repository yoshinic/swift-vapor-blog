import Vapor
import Fluent

final class Blog: Model, Content {
    
    static let schema = "blogs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: .groupID)
    var groupID: UUID
    
    @Field(key: .version)
    var version: Int
    
    @Field(key: .comment)
    var comment: String
    
    @Field(key: .latest)
    var latest: Bool
    
    @OptionalField(key: .picture)
    var picture: Data?
    
    @Field(key: .title)
    var title: String
    
    @Parent(key: .userID)
    var user: User
    
    @Children(for: \.$blog)
    var contents: [BlogContent]
    
    @Siblings(through: BlogTagPivot.self, from: \.$blog, to: \.$tag)
    var tags: [Tag]
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: .deletedAt, on: .delete)
    var deletedAt: Date?
    
    init() { }
    
    init(
        id: Blog.IDValue? = nil,
        groupID: UUID = .init(),
        version: Int = 1,
        comment: String = "",
        latest: Bool = true,
        picture: Data?,
        title: String,
        userID: User.IDValue
    ) {
        self.id = id
        self.groupID = groupID
        self.version = version
        self.comment = comment
        self.latest = latest
        self.picture = picture
        self.title = title
        self.$user.id = userID
    }
}

extension Blog {
    private static func _add(
        _ blog: Blog,
        _ contents: String?,
        _ currentContents: [BlogContent],
        _ tags: String?,
        on db: Database
    ) -> EventLoopFuture<Blog> {
        blog
            .save(on: db)
            .map { blog }
            .flatMapThrowing { blog in
                try BlogContent.add(contents, blog.groupID, blog.id!, currentContents, on: db).map { _ in blog }
            }
            .flatMap { $0 }
            .flatMap { savedBlog in
                var tagSaves: [EventLoopFuture<Void>] = []
                tags?
                    .components(separatedBy: ",")
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .forEach { tagSaves.append(Tag.addTag($0, to: savedBlog, on: db)) }
                return tagSaves.flatten(on: db.eventLoop).map { savedBlog }
            }
        
    }
    
    static func add(
        _ picture: Data?,
        _ title: String,
        _ userID: User.IDValue,
        _ contents: String?,
        _ tags: String?,
        on db: Database
    ) -> EventLoopFuture<Blog> {
        db.transaction { db in
            _add(Blog(picture: picture, title: title, userID: userID), contents, [], tags, on: db)
        }
    }
    
    static func update(
        _ groupID: UUID,
        _ blogID: Blog.IDValue,
        _ userID: User.IDValue,
        _ comment: String?,
        _ picture: Data?,
        _ updatingPicture: Bool,
        _ title: String,
        _ contents: String?,
        _ tags: String?,
        on db: Database
    ) -> EventLoopFuture<Blog> {
        db.transaction { db in
            Blog
                .query(on: db)
                .filter(\.$id == blogID)
                .with(\.$contents)
                .with(\.$tags)
                .first()
                .unwrap(or: Abort(.notFound))
                .flatMap { (blog: Blog) -> EventLoopFuture<Blog> in
                    blog.latest = false
                    return blog.update(on: db).map { blog }
                }
                .map {
                    let new = Blog(
                        groupID: $0.groupID,
                        version: $0.version + 1,
                        comment: comment ?? "",
                        picture: updatingPicture ? picture : $0.picture,
                        title: title,
                        userID: userID
                    )
                    return (new, $0.contents)
                }
                .flatMap { (new, currentContents) in
                    _add(new, contents, currentContents, tags, on: db)
                }
        }
    }
}

extension Array where Element == BlogContent {
    private func convertJSON(_ groupID: UUID, _ blogID: Blog.IDValue) -> [[String: Any]] {
        self.map { $0.convertJSON(groupID, blogID) }
    }
    
    func string(_ groupID: UUID, _ blogID: Blog.IDValue) throws -> String? {
        let a = self.sorted { $0.order < $1.order }
        let dic: [String: Any] = [FieldKey._ops.description: a.convertJSON(groupID, blogID)]
        let data = try JSONSerialization.data(withJSONObject: dic, options: [])
        guard let s = String(data: data, encoding: .utf8) else {
            throw Abort(.noContent, reason: "DB の contents データを quill contents に変換出来ません。")
        }
        return s
    }
    
    func short(_ length: Int) -> String {
        self.compactMap { $0.text }.joined().prefix(length).description
    }
}

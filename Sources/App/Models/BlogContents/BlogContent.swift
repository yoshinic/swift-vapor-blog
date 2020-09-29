import Vapor
import Fluent

extension FieldKey {
    static var _ops: Self { "ops" }
    static var _insert: Self { "insert" }
}

extension FieldKey {
    static var order: Self { "order" }
    static var type: Self { "type" }
    static var attributes: Self { "attributes" }
    static var text: Self { "text" }
    static var data: Self { "data" }
}

final class BlogContent: Model, Content {
    
    static let schema: String = "blog_contents"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: .order)
    var order: Int
    
    @Enum(key: .type)
    var type: BlogContent.ContentType
    
    @Field(key: .attributes)
    var attributes: BlogContentAttribute
    
    @Field(key: .text)
    var text: String
    
    @OptionalField(key: .data)
    var data: Data?
    
    @Parent(key: .blogID)
    var blog: Blog
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: BlogContent.IDValue? = nil,
        order: Int,
        type: BlogContent.ContentType,
        attributes: BlogContentAttribute,
        text: String,
        data: Data?,
        blogID: Blog.IDValue
    ) {
        self.id = id
        self.order = order
        self.type = type
        self.attributes = attributes
        self.text = text
        self.data = data
        self.$blog.id = blogID
    }
}

extension BlogContent {
    private static func _imagePath(_ s: String, _ groupID: UUID) -> Bool {
        let a = s.split(separator: "/", omittingEmptySubsequences: true).map { String($0) }
        return a.count >= 4
            && a[0] == "blogs"
            && a[1] == groupID.uuidString
            && a[3] == BlogContent.ContentType.image.rawValue
    }
    
    static func add(
        _ contents: String?,
        _ groupID: UUID,
        _ blogID: Blog.IDValue,
        _ currentContents: [BlogContent] = [],
        on db: Database
    ) throws -> EventLoopFuture<[BlogContent]> {
        guard
            let s = contents,
            let json = s.data(using: .utf8),
            let quillContents = try JSONSerialization.jsonObject(with: json) as? [String: Any],
            let ops = quillContents[FieldKey._ops.description],
            let inserts = ops as? [[String: Any]]
            else { return db.eventLoop.future([]) }
        var a: [EventLoopFuture<BlogContent>] = []
        inserts.enumerated().forEach { (i, content) in
            let attributes = BlogContentAttribute.make(content[FieldKey.attributes.description])
            guard
                let blogContent = makeBlogContent(i, attributes, content, groupID, blogID, currentContents)
            else { return }
            a += [blogContent.save(on: db).map { blogContent }]
        }
        return a.flatten(on: db.eventLoop)
    }
    
    static func makeBlogContent(
        _ o: Int,
        _ at: BlogContentAttribute,
        _ dic: [String: Any],
        _ groupID: UUID,
        _ blogID: Blog.IDValue,
        _ currentContents: [BlogContent]
    ) -> BlogContent? {
        guard let data = dic[FieldKey._insert.description] as? [String: Any] else {
            return .init(
                order: o,
                type: .text,
                attributes: at,
                text: (dic[FieldKey._insert.description] as? String) ?? "",
                data: nil,
                blogID: blogID
            )
        }
        
        if let s = data[BlogContent.ContentType.formula.rawValue] as? String {
            return .init(order: o, type: .formula, attributes: at, text: s, data: nil, blogID: blogID)
        } else if let image = data[BlogContent.ContentType.image.rawValue] as? String {
            let d: Data?
            let a = image.components(separatedBy: ",")
            if a.count == 2 {
                d = Data(base64Encoded: a[1])
            } else if _imagePath(a[0], groupID),
                let order = Int(image.components(separatedBy: "/").last ?? ""),
                let currentContent = currentContents.first(where: { $0.order == order }) {
                d = currentContent.data
            } else {
                return nil
            }
            return .init(order: o, type: .image, attributes: at, text: "", data: d, blogID: blogID)
        } else if let video = data[BlogContent.ContentType.video.rawValue] as? String {
            return .init(order: o, type: .video, attributes: at, text: video, data: nil, blogID: blogID)
        }
        return nil
    }

    func convertJSON(_ groupID: UUID, _ blogID: Blog.IDValue) -> [String: Any] {
        var dic: [String: Any] = [:]
        if let json = attributes.json {
            dic[FieldKey.attributes.description] = json
        }
        switch type {
        case .text:
            dic[FieldKey._insert.description] = text
        case .formula:
            dic[FieldKey._insert.description] = [
                BlogContent.ContentType.formula.rawValue: text
            ]
        case .image:
            dic[FieldKey._insert.description] = [
                BlogContent.ContentType.image.rawValue:
                    "/blogs/\(groupID)/\(blogID)/\(BlogContent.ContentType.image.rawValue)/\(order)"
            ]
        case .video:
            dic[FieldKey._insert.description] = [
                BlogContent.ContentType.video.rawValue: text
            ]
        case .none:
            break
        }
        return dic
    }
}

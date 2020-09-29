import Fluent

extension BlogContent {
    enum ContentType: String, Codable, CaseIterable {
        static var name: String { "content_type" }
        case none = ""
        case text = "text"
        case image = "image"
        case video = "video"
        case formula = "formula"
    }
}

extension BlogContent.ContentType {
    static func make(_ any: Any?) -> Self {
        guard let s = any as? String, let ret = Self.init(rawValue: s) else { return .none }
        return ret
    }
}

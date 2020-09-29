import Fluent

extension BlogContentAttribute {
    enum ListType: String, Codable, CaseIterable {
        static var name: String { "list_type" }
        case none = ""
        case ordered = "ordered"
        case bullet = "bullet"
    }
}

extension BlogContentAttribute.ListType {
    static func make(_ any: Any?) -> Self {
        guard let s = any as? String, let ret = Self.init(rawValue: s) else { return .none }
        return ret
    }
}

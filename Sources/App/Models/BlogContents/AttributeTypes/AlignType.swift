import Fluent

extension BlogContentAttribute {
    enum AlignType: String, Codable, CaseIterable {
        static var name: String { "align_type" }
        case none = ""
        case right = "right"
        case center = "center"
        case left = "left"
        case justify = "justify"
    }
}

extension BlogContentAttribute.AlignType {
    static func make(_ any: Any?) -> Self {
        guard let s = any as? String, let ret = Self.init(rawValue: s) else { return .none }
        return ret
    }
}

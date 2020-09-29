import Fluent

extension BlogContentAttribute {
    enum DirectionType: String, Codable, CaseIterable {
        static var name: String { "direction_type" }
        case none = ""
        case rtl = "rtl"
        case ltl = "ltl"
    }
}

extension BlogContentAttribute.DirectionType {
    static func make(_ any: Any?) -> Self {
        guard let s = any as? String, let ret = Self.init(rawValue: s) else { return .none }
        return ret
    }
}

import Fluent

extension BlogContentAttribute {
    enum ScriptType: String, Codable, CaseIterable {
        static var name: String { "script_type" }
        case none = ""
        case sub = "sub"
        case `super` = "super"
    }
}

extension BlogContentAttribute.ScriptType {
    static func make(_ any: Any?) -> Self {
        guard let s = any as? String, let ret = Self.init(rawValue: s) else { return .none }
        return ret
    }
}

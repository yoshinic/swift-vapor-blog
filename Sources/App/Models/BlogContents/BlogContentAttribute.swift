import Foundation
import Fluent

extension FieldKey {
    static var font: Self { "font" }
    static var size: Self { "size" }
    static var bold: Self { "bold" }
    static var italic: Self { "italic" }
    static var underline: Self { "underline" }
    static var strike: Self { "strike" }
    static var color: Self { "color" }
    static var background: Self { "background" }
    static var script: Self { "script" }
    static var header: Self { "header" }
    static var blockquote: Self { "blockquote" }
    static var codeBlock: Self { "code-block" }
    static var list: Self { "list" }
    static var indent: Self { "indent" }
    static var align: Self { "align" }
    static var direction: Self { "direction" }
    static var link: Self { "link" }
}

final class BlogContentAttribute: Fields {
    static var `default`: BlogContentAttribute {
        .init(font: "",
              size: "",
              bold: false,
              italic: false,
              underline: false,
              strike: false,
              color: "",
              background: "",
              script: .none,
              header: 0,
              blockquote: false,
              codeBlock: false,
              list: .none,
              indent: 0,
              align: .none,
              direction: .none,
              link: ""
        )
    }
    
    @Field(key: .font)
    var font: String
    
    @Field(key: .size)
    var size: String
    
    @Field(key: .bold)
    var bold: Bool
    
    @Field(key: .italic)
    var italic: Bool
    
    @Field(key: .underline)
    var underline: Bool
    
    @Field(key: .strike)
    var strike: Bool
    
    @Field(key: .color)
    var color: String
    
    @Field(key: .background)
    var background: String
    
    @Enum(key: .script)
    var script: BlogContentAttribute.ScriptType
    
    @Field(key: .header)
    var header: Int
    
    @Field(key: .blockquote)
    var blockquote: Bool
    
    @Field(key: .codeBlock)
    var codeBlock: Bool
    
    @Enum(key: .list)
    var list: BlogContentAttribute.ListType
    
    @Field(key: .indent)
    var indent: Int
    
    @Enum(key: .align)
    var align: BlogContentAttribute.AlignType
    
    @Enum(key: .direction)
    var direction: BlogContentAttribute.DirectionType
    
    @Field(key: .link)
    var link: String
    
    init() { }
    
    init(
        font: String,
        size: String,
        bold: Bool,
        italic: Bool,
        underline: Bool,
        strike: Bool,
        color: String,
        background: String,
        script: BlogContentAttribute.ScriptType,
        header: Int,
        blockquote: Bool,
        codeBlock: Bool,
        list: BlogContentAttribute.ListType,
        indent: Int,
        align: BlogContentAttribute.AlignType,
        direction: BlogContentAttribute.DirectionType,
        link: String
    ) {
        self.font = font
        self.size = size
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strike = strike
        self.color = color
        self.background = background
        self.script = script
        self.header = header
        self.blockquote = blockquote
        self.codeBlock = codeBlock
        self.list = list
        self.indent = indent
        self.align = align
        self.direction = direction
        self.link = link
    }
}

extension BlogContentAttribute {
    static func make(_ any: Any?) -> BlogContentAttribute {
        guard let dic = any as? [String: Any] else { return .default }
        let font = (dic[FieldKey.font.description] as? String) ?? ""
        let size = (dic[FieldKey.size.description] as? String) ?? ""
        let bold = (dic[FieldKey.bold.description] as? Bool) ?? false
        let italic = (dic[FieldKey.italic.description] as? Bool) ?? false
        let underline = (dic[FieldKey.underline.description] as? Bool) ?? false
        let strike = (dic[FieldKey.strike.description] as? Bool) ?? false
        let color = (dic[FieldKey.color.description] as? String) ?? ""
        let background = (dic[FieldKey.background.description] as? String) ?? ""
        let script = BlogContentAttribute.ScriptType.make(dic[FieldKey.script.description])
        let header = (dic[FieldKey.header.description] as? Int) ?? 0
        let blockquote = (dic[FieldKey.blockquote.description] as? Bool) ?? false
        let codeBlock = (dic[FieldKey.codeBlock.description] as? Bool) ?? false
        let list = BlogContentAttribute.ListType.make(dic[FieldKey.list.description])
        let indent = (dic[FieldKey.indent.description] as? Int) ?? 0
        let align = BlogContentAttribute.AlignType.make(dic[FieldKey.align.description])
        let direction = BlogContentAttribute.DirectionType.make(dic[FieldKey.direction.description])
        let link = (dic[FieldKey.link.description] as? String) ?? ""
        
        return .init(
            font: font,
            size: size,
            bold: bold,
            italic: italic,
            underline: underline,
            strike: strike,
            color: color,
            background: background,
            script: script,
            header: header,
            blockquote: blockquote,
            codeBlock: codeBlock,
            list: list,
            indent: indent,
            align: align,
            direction: direction,
            link: link
        )
    }
}

extension BlogContentAttribute {
    var json: [String: Any]? {
        guard self != .default else { return nil }
        var dic: [String: Any] = [:]
        if font.isEmpty == false {
            dic[FieldKey.font.description] = font
        }
        if size.isEmpty == false {
            dic[FieldKey.size.description] = size
        }
        if bold {
            dic[FieldKey.bold.description] = true
        }
        if italic {
            dic[FieldKey.italic.description] = true
        }
        if underline {
            dic[FieldKey.underline.description] = true
        }
        if strike {
            dic[FieldKey.strike.description] = true
        }
        if color.isEmpty == false {
            dic[FieldKey.color.description] = color
        }
        if background.isEmpty == false {
            dic[FieldKey.background.description] = background
        }
        if script != .none {
            dic[FieldKey.script.description] = script.rawValue
        }
        if header > 0 {
            dic[FieldKey.header.description] = header
        }
        if blockquote {
            dic[FieldKey.blockquote.description] = true
        }
        if codeBlock {
            dic[FieldKey.codeBlock.description] = true
        }
        if list != .none {
            dic[FieldKey.list.description] = list.rawValue
        }
        if indent > 0 {
            dic[FieldKey.indent.description] = indent
        }
        if align != .none {
            dic[FieldKey.align.description] = align.rawValue
        }
        if direction != .none {
            dic[FieldKey.direction.description] = direction.rawValue
        }
        if link.isEmpty == false {
            dic[FieldKey.link.description] = link
        }
        return dic
    }
}

extension BlogContentAttribute: Equatable {
    static func == (lhs: BlogContentAttribute, rhs: BlogContentAttribute) -> Bool {
        lhs.font == rhs.font
            && lhs.size == rhs.size
            && lhs.bold == rhs.bold
            && lhs.italic == rhs.italic
            && lhs.underline == rhs.underline
            && lhs.strike == rhs.strike
            && lhs.color == rhs.color
            && lhs.background == rhs.background
            && lhs.script == rhs.script
            && lhs.header == rhs.header
            && lhs.blockquote == rhs.blockquote
            && lhs.codeBlock == rhs.codeBlock
            && lhs.list == rhs.list
            && lhs.indent == rhs.indent
            && lhs.align == rhs.align
            && lhs.direction == rhs.direction
            && lhs.link == rhs.link
    }
}

import Vapor
import Leaf

struct ModuloTag: LeafTag {
    static let name = "modulo"

    func render(_ ctx: LeafContext) throws -> LeafData {
        guard
            ctx.parameters.count == 2,
            let lhs = ctx.parameters[0].int,
            let rhs = ctx.parameters[1].int
            else { throw "引数は２つの整数型にして下さい" }
        return .int(lhs % rhs)
    }
}

// 重複無しの配列のみ
struct IndexTag: LeafTag {
    static let name = "index"

    func render(_ ctx: LeafContext) throws -> LeafData {
        guard
            ctx.parameters.count == 2,
            let a = ctx.parameters[0].array,
            let i = a.firstIndex(of: ctx.parameters[1])
            else { throw "引数には配列とその要素を一つずつ指定して下さい。" }
        return .int(i)
    }
}

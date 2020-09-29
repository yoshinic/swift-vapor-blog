import Fluent

extension BlogContentAttribute.DirectionType {
    static func create(on database: Database) -> EventLoopFuture<DatabaseSchema.DataType> {
        allCases
            .reduce(into: database.enum(name)) { $0 = $0.case($1.rawValue) }
            .create()
    }
}

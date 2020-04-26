import Vapor
import Fluent

final class UserToken: Model, Content {
    static var schema: String = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    
    init(
        id: UserToken.IDValue? = nil,
        value: String,
        userID: User.IDValue
    ) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension UserToken: ModelTokenAuthenticatable {
    typealias User = App.User
    
    static var valueKey: KeyPath<UserToken, Field<String>> {
        return \.$value
    }
    
    static var userKey: KeyPath<UserToken, Parent<User>> {
        return \UserToken.$user
    }
    
    var isValid: Bool {
        return true
    }
}


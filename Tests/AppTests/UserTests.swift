@testable import App
import XCTVapor
import FluentPostgresDriver

final class UserTests: XCTestCase {
    
    let usersName = "テスト名"
    let usersUsername = "テストユーザー名"
    let userPassword = "テストパスワード"
    let usersURI = "/api/users/"
    
    override func setUp() { }
    override func tearDown() { }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        try _test { app in
            let user = try User.create(name: usersName, username: usersUsername, on: app.db)
            _ = try User.create(on: app.db)
            try app.test(.GET, usersURI) { response in
                let users = try response.content.decode([User.Public].self)
                XCTAssertEqual(users.count, 2)
                XCTAssertEqual(users[0].name, usersName)
                XCTAssertEqual(users[0].username, usersUsername)
                XCTAssertEqual(users[0].id, user.id)
            }
        }
    }
    
    func testUserCanBeSavedWithAPI() throws {
        try _test { app in
            let user = User.Create(name: usersName,
                                   username: usersUsername,
                                   password: "password")
            try app
                .test(
                    .POST,
                    usersURI,
                    headers: .init([("Content-Type", "application/json")]),
                    beforeRequest: { request in
                        try request.content.encode(user)
                },
                    afterResponse: { response in
                        let receivedUser = try response.content.decode(User.Public.self)
                        XCTAssertEqual(receivedUser.name, usersName)
                        XCTAssertEqual(receivedUser.username, usersUsername)
                        XCTAssertNotNil(receivedUser.id)
                        
                        try app.test(.GET, usersURI) { response in
                            let users = try response.content.decode([User.Public].self)
                            XCTAssertEqual(users.count, 1)
                            XCTAssertEqual(users[0].name, usersName)
                            XCTAssertEqual(users[0].username, usersUsername)
                            XCTAssertEqual(users[0].id, receivedUser.id)
                        }
                }
            )
        }
    }
    
    func testGettingASingleUserFromTheAPI() throws {
        try _test { app in
            let user = try User.create(name: usersName, username: usersUsername, on: app.db)
            try app.test(.GET, "\(usersURI)\(user.id!)") { response in
                let receivedUser = try response.content.decode(User.Public.self)
                XCTAssertEqual(receivedUser.name, usersName)
                XCTAssertEqual(receivedUser.username, usersUsername)
                XCTAssertEqual(receivedUser.id, user.id)
            }
        }
    }
    
    func testGettingAUsersBlogsFromTheAPI() throws {
        try _test { app in
            let user = try User.create(on: app.db)
            let blogTitle = "テスト"
            let blogContents = "データ"
            let blog1 = try Blog.create(title: blogTitle, contents: blogContents, user: user, on: app.db)
            _ = try Blog.create(title: "テストタイトル２", contents: "テスト内容２", user: user, on: app.db)
            
            try app.test(.GET, "\(usersURI)\(user.id!)/blogs") { response in
                let blogs = try response.content.decode([Blog].self)
                XCTAssertEqual(blogs.count, 2)
                XCTAssertEqual(blogs[0].id, blog1.id)
                XCTAssertEqual(blogs[0].title, blogTitle)
                XCTAssertEqual(blogs[0].contents, blogContents)
            }
        }
    }
    
    // 保存した User を更新できるか確認
    func testUpdatingAnUser() throws {
        try _test { app in
            let user = try User.create(name: usersName, username: usersUsername, on: app.db)
            let newUsername = "更新ユーザー名"
            let newPassword = "9999"
            let updatedUser = User.Create(name: usersName, username: newUsername, password: newPassword)
            try app
                .test(
                    .PUT,
                    "\(usersURI)\(user.id!)",
                    headers: .init([("Content-Type", "application/json")]),
                    beforeRequest: { request in
                        try request.content.encode(updatedUser)
                },
                    afterResponse: { response in
                        try app.test(.GET, "\(usersURI)\(user.id!)") { response in
                            let returnedUser = try response.content.decode(User.Public.self)
                            XCTAssertEqual(returnedUser.name, usersName)
                            XCTAssertEqual(returnedUser.username, newUsername)
                        }
                })
        }
    }
    
    // 保存した User を更新するとき、同じユーザー名が存在するとき更新しないか確認
    func testUpdatingErrorAnUser() throws {
        try _test { app in
            let _ = try User.create(name: usersName, username: usersUsername, on: app.db)
            
            let oldName = "適当名"
            let oldUsername = "適当ユーザー名"
            let user = try User.create(name: oldName, username: oldUsername, on: app.db)
            
            let newName = "更新名"
            let newPassword = "更新パスワード"
            let updatedUser = User.Create(name: newName, username: usersUsername, password: newPassword)
            try app
                .test(
                    .PUT,
                    "\(usersURI)\(user.id!)",
                    headers: .init([("Content-Type", "application/json")]),
                    beforeRequest: { request in
                        try request.content.encode(updatedUser)
                },
                    afterResponse: { response in
                        XCTAssertEqual(response.status, .badRequest)
                        
                        try app.test(.GET, usersURI) { response in
                            let users = try response.content.decode([User.Public].self)
                            XCTAssertEqual(users.count, 2)
                            XCTAssertEqual(users[0].name, usersName)
                            XCTAssertEqual(users[0].username, usersUsername)
                            XCTAssertEqual(users[1].name, oldName)
                            XCTAssertEqual(users[1].username, oldUsername)
                        }
                })
        }
    }
    
    // 保存した User を削除できるか確認
    func testDeletingAnUser() throws {
        try _test { app in
            let user = try User.create(on: app.db)
            try app.test(.GET, usersURI) { response in
                var users = try response.content.decode([User.Public].self)
                XCTAssertEqual(users.count, 1)
                
                try app
                    .test(.DELETE, "\(usersURI)\(user.id!)")
                    .test(.GET, usersURI) { response in
                        users = try response.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 0)
                }
            }
        }
    }
    
    static let allTests = [
        ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
        ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
        ("testGettingASingleUserFromTheAPI", testGettingASingleUserFromTheAPI),
        ("testGettingAUsersBlogsFromTheAPI", testGettingAUsersBlogsFromTheAPI),
        ("testUpdatingAnUser", testUpdatingAnUser),
        ("testUpdatingErrorAnUser", testUpdatingErrorAnUser),
        ("testDeletingAnUser", testDeletingAnUser)
    ]
}


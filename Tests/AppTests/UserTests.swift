@testable import App
import XCTVapor

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
            try app.test(.GET, usersURI, afterResponse:  { response in
                let users = try response.content.decode([User.Public].self)
                XCTAssertEqual(users.count, 3)
                XCTAssertEqual(users[1].name, usersName)
                XCTAssertEqual(users[1].username, usersUsername)
                XCTAssertEqual(users[1].id, user.id)
            })
        }
    }
    
    func testUserCanBeSavedWithAPI() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            let user = User.Create(name: usersName,
                                   username: usersUsername,
                                   password: "password")
            let incorrectUser = User.Create(name: usersName,
                                            username: usersUsername,
                                            password: "passwor")
            
            var headers = headers
            headers.add(name: "Content-Type", value: "application/json")
            try app
                .test(
                    .POST,
                    usersURI,
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(user)
                },
                    afterResponse: { response in
                        let receivedUser = try response.content.decode(User.Public.self)
                        XCTAssertEqual(receivedUser.name, usersName)
                        XCTAssertEqual(receivedUser.username, usersUsername)
                        XCTAssertNotNil(receivedUser.id)
                        
                        try app.test(.GET, usersURI, afterResponse:  { response in
                            let users = try response.content.decode([User.Public].self)
                            XCTAssertEqual(users.count, 2)
                            XCTAssertEqual(users[1].name, usersName)
                            XCTAssertEqual(users[1].username, usersUsername)
                            XCTAssertEqual(users[1].id, receivedUser.id)
                        })
                }
            )
                .test(
                    .POST,
                    usersURI,
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(incorrectUser)
                },
                    afterResponse: { response in
                        do {
                            let _ = try response.content.decode(User.Public.self)
                            XCTAssert(false)
                        } catch {
                            XCTAssert(true)
                        }
                }
            )
        }
    }
    
    func testGettingASingleUserFromTheAPI() throws {
        try _test { app in
            let user = try User.create(name: usersName, username: usersUsername, on: app.db)
            try app.test(.GET, "\(usersURI)\(user.id!)", afterResponse:  { response in
                let receivedUser = try response.content.decode(User.Public.self)
                XCTAssertEqual(receivedUser.name, usersName)
                XCTAssertEqual(receivedUser.username, usersUsername)
                XCTAssertEqual(receivedUser.id, user.id)
            })
        }
    }
    
    func testGettingAUsersBlogsFromTheAPI() throws {
        try _test { app in
            let user = try User.create(on: app.db)
            let blogTitle = "テスト"
            let blog1 = try Blog.create(title: blogTitle, user: user, on: app.db)
            _ = try Blog.create(title: "テストタイトル２", user: user, on: app.db)
            
            try app.test(.GET, "\(usersURI)\(user.id!)/blogs", afterResponse:  { response in
                let blogs = try response.content.decode([Blog].self)
                XCTAssertEqual(blogs.count, 2)
                XCTAssertEqual(blogs[0].id, blog1.id)
                XCTAssertEqual(blogs[0].title, blogTitle)
            })
        }
    }
    
    // 保存した User を更新できるか確認
    func testUpdatingAnUser() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            var headers = headers
            headers.add(name: "Content-Type", value: "application/json")
            
            let user = try User.create(name: usersName, username: usersUsername, on: app.db)
            let newUsername = "更新ユーザー名"
            let newPassword = "9999"
            let updatedUser = User.Create(name: usersName, username: newUsername, password: newPassword)
            try app
                .test(
                    .PUT,
                    "\(usersURI)\(user.id!)",
                    beforeRequest: { request in
                        try request.content.encode(updatedUser)
                },
                    afterResponse: { response in
                        try app.test(.GET, "\(usersURI)\(user.id!)", afterResponse:  { response in
                            let returnedUser = try response.content.decode(User.Public.self)
                            XCTAssertEqual(returnedUser.name, usersName)
                            XCTAssertEqual(returnedUser.username, usersUsername)
                        })
                })
                .test(
                    .PUT,
                    "\(usersURI)\(user.id!)",
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(updatedUser)
                },
                    afterResponse: { response in
                        try app.test(.GET, "\(usersURI)\(user.id!)", afterResponse:  { response in
                            let returnedUser = try response.content.decode(User.Public.self)
                            XCTAssertEqual(returnedUser.name, usersName)
                            XCTAssertEqual(returnedUser.username, newUsername)
                        })
                })
        }
    }
    
    // 保存した User を更新するとき、同じユーザー名が存在するとき更新しないか確認
    func testUpdatingErrorAnUser() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            var headers = headers
            headers.add(name: "Content-Type", value: "application/json")
            
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
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(updatedUser)
                },
                    afterResponse: { response in
                        XCTAssertEqual(response.status, .badRequest)
                        
                        try app.test(.GET, usersURI, afterResponse:  { response in
                            let users = try response.content.decode([User.Public].self)
                            XCTAssertEqual(users.count, 3)
                            XCTAssertEqual(users[1].name, usersName)
                            XCTAssertEqual(users[1].username, usersUsername)
                            XCTAssertEqual(users[2].name, oldName)
                            XCTAssertEqual(users[2].username, oldUsername)
                        })
                })
        }
    }
    
    // 保存した User を Soft Delete & Restore できるか確認
    func testSoftDeletingAndRestoringAnUser() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            let user = try User.create(on: app.db)
            try app.test(.GET, usersURI, headers: headers, afterResponse:  { response in
                var users = try response.content.decode([User.Public].self)
                XCTAssertEqual(users.count, 2)
                
                try app
                    .test(.DELETE, "\(usersURI)\(user.id!)")
                    .test(.GET, usersURI, afterResponse:  { response in
                        users = try response.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 2)
                    })
                    .test(.DELETE, "\(usersURI)\(user.id!)", headers: headers)
                    .test(.GET, usersURI, afterResponse:  { response in
                        users = try response.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 1)
                        
                        let count = try app.db.query(User.self).withDeleted().count().wait()
                        XCTAssertEqual(count, 2)
                    })
                    .test(.POST, "\(usersURI)\(user.id!)/restore", headers: headers)
                    .test(.GET, usersURI, afterResponse:  { response in
                        users = try response.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 2)
                        
                        let count = try app.db.query(User.self).withDeleted().count().wait()
                        XCTAssertEqual(count, 2)
                    })
                
            })
        }
    }
    
    func testForceDeletingAnUser() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            let user = try User.create(on: app.db)
            try app.test(.GET, usersURI, headers: headers, afterResponse:  { response in
                var users = try response.content.decode([User.Public].self)
                XCTAssertEqual(users.count, 2)
                
                try app
                    .test(.DELETE, "\(usersURI)\(user.id!)/force")
                    .test(.GET, usersURI, afterResponse:  { response in
                        users = try response.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 2)
                    })
                    .test(.DELETE, "\(usersURI)\(user.id!)/force", headers: headers)
                    .test(.GET, usersURI, afterResponse:  { response in
                        users = try response.content.decode([User.Public].self)
                        XCTAssertEqual(users.count, 1)
                        
                        let count = try app.db.query(User.self).withDeleted().count().wait()
                        XCTAssertEqual(count, 1)
                    })
            })
        }
    }
    
    static let allTests = [
        ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
        ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
        ("testGettingASingleUserFromTheAPI", testGettingASingleUserFromTheAPI),
        ("testGettingAUsersBlogsFromTheAPI", testGettingAUsersBlogsFromTheAPI),
        ("testUpdatingAnUser", testUpdatingAnUser),
        ("testUpdatingErrorAnUser", testUpdatingErrorAnUser),
        ("testSoftDeletingAndRestoringAnUser", testSoftDeletingAndRestoringAnUser),
        ("testForceDeletingAnUser", testForceDeletingAnUser)
    ]
}


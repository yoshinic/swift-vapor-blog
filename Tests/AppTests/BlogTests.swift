@testable import App
import XCTVapor

final class BlogTests: XCTestCase {
    
    let blogsURI = "/api/blogs/"
    let blogTitle = "テスト"
    let blogContents = "データ"
    
    override func setUp() { }
    
    override func tearDown() { }
    
    // Blogを複数作成したとき区別されているか確認
    func testBlogsCanBeRetrievedFromAPI() throws {
        try _test { app in
            let blog1 = try Blog.create(title: blogTitle, contents: blogContents, on: app.db)
            _ = try Blog.create(on: app.db)
            try app.test(.GET, blogsURI) { response in
                let blogs = try response.content.decode([Blog].self)
                XCTAssertEqual(blogs.count, 2)
                XCTAssertEqual(blogs[0].title, blogTitle)
                XCTAssertEqual(blogs[0].contents, blogContents)
                XCTAssertEqual(blogs[0].id, blog1.id)
                XCTAssertEqual(blogs[0].$user.id, blog1.$user.id)
            }
        }
    }
    
    // Blog が保存されるか確認
    func testBlogCanBeSavedWithAPI() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            var headers = headers
            headers.add(name: "Content-Type", value: "application/json")
            let newUser = try User.create(on: app.db)
            let blog = Blog(pictureBase64: "", title: blogTitle, contents: blogContents, userID: newUser.id!)
            try app
                .test(
                    .POST,
                    blogsURI,
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(blog)
                },
                    afterResponse: { response in
                        let receivedBlog = try response.content.decode(Blog.self)
                        XCTAssertEqual(receivedBlog.title, blogTitle)
                        XCTAssertEqual(receivedBlog.contents, blogContents)
                        XCTAssertNotNil(receivedBlog.id)
                        XCTAssertNotNil(receivedBlog.$user.id)
                        
                        try app.test(.GET, blogsURI) { response in
                            let blogs = try response.content.decode([Blog].self)
                            XCTAssertEqual(blogs.count, 1)
                            XCTAssertEqual(blogs[0].title, blogTitle)
                            XCTAssertEqual(blogs[0].contents, blogContents)
                            XCTAssertEqual(blogs[0].id, receivedBlog.id)
                            XCTAssertEqual(blogs[0].$user.id, receivedBlog.$user.id)
                        }
                })
        }
    }
    
    // Blog を１つ取得できるか確認
    func testGettingASingleBlogFromTheAPI() throws {
        try _test { app in
            let blog = try Blog.create(title: blogTitle, contents: blogContents, on: app.db)
            try app.test(.GET, "\(blogsURI)\(blog.id!)") { response in
                let returnedBlog = try response.content.decode(Blog.self)
                XCTAssertEqual(returnedBlog.title, blogTitle)
                XCTAssertEqual(returnedBlog.contents, blogContents)
                XCTAssertEqual(returnedBlog.id, blog.id)
                XCTAssertEqual(returnedBlog.$user.id, blog.$user.id)
            }
        }
    }
    
    // Blog を作成したユーザーを取得できるか確認
    func testGettingAnBlogsUser() throws {
        try _test { app in
            let user = try User.create(on: app.db)
            let blog = try Blog.create(user: user, on: app.db)
            try app.test(.GET, "\(blogsURI)\(blog.id!)/user") { response in
                let blogsUser = try response.content.decode(User.self)
                XCTAssertEqual(blogsUser.id, user.id)
                XCTAssertEqual(blogsUser.name, user.name)
                XCTAssertEqual(blogsUser.username, user.username)
            }
        }
    }
    
    // 保存した Blog を更新できるか確認
    func testUpdatingAnBlog() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            var headers = headers
            headers.add(name: "Content-Type", value: "application/json")
            let blog = try Blog.create(title: blogTitle, contents: blogContents, on: app.db)
            let newContents = "更新内容"
            let newUser = try User.create(on: app.db)
            let updatedBlog = Blog(pictureBase64: "", title: blogTitle, contents: newContents, userID: newUser.id!)
            try app
                .test(
                    .PUT,
                    "\(blogsURI)\(blog.id!)",
                    beforeRequest: { request in
                        try request.content.encode(updatedBlog)
                },
                    afterResponse: { response in
                        try app.test(.GET, "\(blogsURI)\(blog.id!)") { response in
                            let returnedBlog = try response.content.decode(Blog.self)
                            XCTAssertEqual(returnedBlog.title, blogTitle)
                            XCTAssertEqual(returnedBlog.contents, blogContents)
                        }
                })
                .test(
                    .PUT,
                    "\(blogsURI)\(blog.id!)",
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(updatedBlog)
                },
                    afterResponse: { response in
                        try app.test(.GET, "\(blogsURI)\(blog.id!)") { response in
                            let returnedBlog = try response.content.decode(Blog.self)
                            XCTAssertEqual(returnedBlog.title, blogTitle)
                            XCTAssertEqual(returnedBlog.contents, newContents)
                            XCTAssertEqual(returnedBlog.$user.id, newUser.id!)
                        }
                })
        }
    }
    
    // 保存した Blog を削除できるか確認
    func testDeletingAnBlog() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            let blog = try Blog.create(on: app.db)
            try app.test(.GET, blogsURI) { response in
                var blogs = try response.content.decode([Blog].self)
                XCTAssertEqual(blogs.count, 1)
                
                try app
                    .test(.DELETE, "\(blogsURI)\(blog.id!)")
                    .test(.GET, blogsURI) { response in
                        blogs = try response.content.decode([Blog].self)
                        XCTAssertEqual(blogs.count, 1)
                }
                .test(.DELETE, "\(blogsURI)\(blog.id!)", headers: headers)
                .test(.GET, blogsURI) { response in
                    blogs = try response.content.decode([Blog].self)
                    XCTAssertEqual(blogs.count, 0)
                }
            }
        }
    }
    
    func testBlogsTags() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            let tag = try Tag.create(on: app.db)
            let tag2 = try Tag.create(name: "swift", on: app.db)
            let blog = try Blog.create(on: app.db)
            
            let request1URL = "\(blogsURI)\(blog.id!)/tags/\(tag.id!)"
            let request2URL = "\(blogsURI)\(blog.id!)/tags/\(tag2.id!)"
            
            try app
                .test(.POST, request1URL, headers: headers)
                .test(.POST, request2URL, headers: headers)
                .test(.GET, "\(blogsURI)\(blog.id!)/tags") { response in
                    let tags = try response.content.decode([App.Tag].self)
                    XCTAssertEqual(tags.count, 2)
                    XCTAssertEqual(tags[0].id, tag.id)
                    XCTAssertEqual(tags[0].name, tag.name)
                    XCTAssertEqual(tags[1].id, tag2.id)
                    XCTAssertEqual(tags[1].name, tag2.name)
                    
                    let request3URL = "\(blogsURI)\(blog.id!)/tags/\(tag.id!)"
                    try app
                        .test(.DELETE, request3URL, headers: headers)
                        .test(.GET, "\(blogsURI)\(blog.id!)/tags") { response in
                            let newTags = try response.content.decode([App.Tag].self)
                            XCTAssertEqual(newTags.count, 1)
                    }
            }
        }
    }
    
    static let allTests = [
        ("testBlogsCanBeRetrievedFromAPI", testBlogsCanBeRetrievedFromAPI),
        ("testBlogCanBeSavedWithAPI", testBlogCanBeSavedWithAPI),
        ("testGettingASingleBlogFromTheAPI", testGettingASingleBlogFromTheAPI),
        ("testGettingAnBlogsUser", testGettingAnBlogsUser),
        ("testUpdatingAnBlog", testUpdatingAnBlog),
        ("testDeletingAnBlog", testDeletingAnBlog),
        ("testBlogsTags", testBlogsTags)
    ]
}

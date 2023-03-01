//
//  STURLRequest.swift
//  STBaseProject_Example
//
//  Created by song on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import Alamofire

struct STURLRequest {
    
    static func request(url: String, method: HTTPMethod) throws -> URLRequest{
        var request: URLRequest = try URLRequest.init(url: url, method: method)
        request.timeoutInterval = 15
        request.setValue("Bearer \(STURLRequest.authorization())", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private static func authorization() -> String {
        return "eyJhbGciOiJIUzUxMiJ9.eyJ1bmlvbklkIjoiODU1RkM3NjZBM0UyRDgzMkY5NUZFREY1MDBENzJFRDQ5NjE2OTQwNDA0NkUzMjMyRjRGODVGREIxRTUxQTJBNSIsInBob25lIjoiQUEzNDFBQzMxREQ4NzU4NjZBODNDODJEMjU1QTVBMjYiLCJzeXNUYWciOjEsImNyZWF0ZWQiOjE2NzcyNDA5MDc0MDcsInVzZXJMZXZlbHMiOjE2LCJpZCI6IkFCQzRGNDIwQzBGNDUzRTg2ODM4QjE5NkY0NzU5MjhDIiwiZXhwIjoxNzYzNjQwOTA3LCJ1bmlvblByZWZpeCI6IiJ9.xDlUkt0V6aroWjLZOYbSuqhLGSHbeAwzenFukDNY_Dygj0d3HwNry3rIxLoHS5hhOZYS-6JEe_sbBlVVoUlHaA"
    }
}

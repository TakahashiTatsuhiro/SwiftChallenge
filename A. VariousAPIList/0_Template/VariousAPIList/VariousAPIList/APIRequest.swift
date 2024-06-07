import Foundation


protocol APIRequest {
    associatedtype ResponseType: Decodable
    var endpoint: String { get }
    var method: HttpMethod { get }
    var headers: [String: String] { get }
    var baseURL: URL? { get }
    var parameters: [String: String] { get }
}

struct GetAlbumsRequest: APIRequest {
    typealias ResponseType = [Album]
    var endpoint = "/albums"
    var method: HttpMethod = .GET
    var headers: [String : String] = [String:String]()
    var baseURL: URL? = URL(string: "https://jsonplaceholder.typicode.com")
    var parameters: [String : String] = [String:String]()
}

struct GetPhotosRequest: APIRequest {
    typealias ResponseType = [Photo]
    var endpoint = "/photos"
    var method: HttpMethod = .GET
    var headers: [String : String] = [:]
    var baseURL: URL? = URL(string: "https://jsonplaceholder.typicode.com")
    var parameters: [String : String] = [String:String]()
}

import Foundation
import Combine

enum HttpMethod: String {
    case GET
}

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
    var method: HttpMethod
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

protocol APIClient {
    func executeWithCompletion<T: APIRequest>(_ request: T, completion: @escaping (T.ResponseType?, Error?) -> Void)
//    func executeWithFuture<T: APIRequest>(_ request: T) -> Future<T.ResponseType, Error>
    func executeWithAsyncThrows<T: APIRequest>(_ request: T) async throws -> T.ResponseType
    func executeWithAsyncResult<T: APIRequest>(_ request: T) async -> Result<T.ResponseType, Error>
}

class APIClientImpl: APIClient {
    func executeWithCompletion<T>(_ request: T, completion: @escaping (T.ResponseType?, (any Error)?) -> Void) where T: APIRequest {
        
        // https://qiita.com/imchino/items/615ef4baf683cfd91d3b
        var urlComponent = URLComponents(url: request.baseURL!, resolvingAgainstBaseURL: true)!
        urlComponent.path = request.endpoint
        urlComponent.queryItems = request.parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponent.url else {
            completion(nil, URLError(.badURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
            } else if let data = data {
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode(T.ResponseType.self, from: data)
                    completion(decoded, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
//    func executeWithFuture<T>(_ request: T) -> Future<T.ResponseType, any Error> where T : APIRequest {
//        
//    }
    
    func executeWithAsyncThrows<T>(_ request: T) async throws -> T.ResponseType where T : APIRequest {
        // https://qiita.com/imchino/items/615ef4baf683cfd91d3b
        var urlComponent = URLComponents(url: request.baseURL!, resolvingAgainstBaseURL: true)!
        urlComponent.path = request.endpoint
        urlComponent.queryItems = request.parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponent.url else {
            throw URLError(.badURL)
        }

        // https://qiita.com/kamomeKUN/items/a68ca0d7f65565010b06
        let (data, urlResponse) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(T.ResponseType.self, from: data)
            return decoded
        } catch {
            throw error
        }
    }
    
    func executeWithAsyncResult<T>(_ request: T) async -> Result<T.ResponseType, any Error> where T : APIRequest {
        // https://qiita.com/imchino/items/615ef4baf683cfd91d3b
        var urlComponent = URLComponents(url: request.baseURL!, resolvingAgainstBaseURL: true)!
        urlComponent.path = request.endpoint
        urlComponent.queryItems = request.parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponent.url else {
            return Result.failure(URLError(.badURL))
        }

        do {
            let (data, urlResponse) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.ResponseType.self, from: data)
            return Result.success(decoded)
        } catch {
            return Result.failure(error)
        }
    }
}

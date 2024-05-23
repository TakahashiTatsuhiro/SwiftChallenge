import Foundation

struct Photo: Codable, Hashable {
    var albumId: Int64
    var id: Int64
    var title: String
    var url: URL
    var thumbnailUrl: URL
}

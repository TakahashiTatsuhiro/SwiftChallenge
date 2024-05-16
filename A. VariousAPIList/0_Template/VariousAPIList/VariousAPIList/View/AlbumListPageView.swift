import SwiftUI

struct AlbumListPageView: View {
    @StateObject var viewModel: AlbumViewModel
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.albumList, id: \.self) { album in
                AlbumView(album: album)
                Divider()
            }
        }
    }
}

typealias AlbumList = [Album]

extension AlbumListPageView {
    
    class AlbumViewModel: ObservableObject {
        @Published var albumList: AlbumList = []
        
        init() {
            fetchAlbum { _returnVal, _error in
                if let returnVal = _returnVal {
                    self.albumList = returnVal
                } else if let error = _error {
                    print(error)
                }
            }
        }
        
        func fetchAlbum(completion: @escaping (AlbumList?, Error?) -> Void) {
            //参考 https://zenn.dev/masakatsu_tagi/articles/f5374dd3153bdc
            
            let requestUrl = URL(string: "https://jsonplaceholder.typicode.com/albums")!
            let task = URLSession.shared.dataTask(with: requestUrl) { data, response, error in
                
                if let error = error {
                    completion(nil, error)
                } else if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let decoded = try decoder.decode(AlbumList.self, from: data)
                        completion(decoded, nil)
                    } catch {
                        print("error")
                    }
                }
            }
            
            task.resume()
        }
    }
}

struct AlbumView : View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("userId: \(album.userId)")
            Text("id: \(album.id)")
            Text("title: \(album.title)")
        }
    }
}

//#Preview {
//    AlbumListPageView()
//}

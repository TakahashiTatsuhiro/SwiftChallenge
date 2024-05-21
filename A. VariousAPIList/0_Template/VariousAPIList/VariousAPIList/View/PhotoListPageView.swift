import SwiftUI

struct PhotoListPageView: View {
    @StateObject var viewModel: PhotoViewModel
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.photoList, id: \.self) { photo in
                PhotoView(photo: photo)
                Divider()
            }
        }
    }
}

typealias PhotoList = [Photo]

extension PhotoListPageView {
    
    class PhotoViewModel: ObservableObject {
        @Published var photoList: PhotoList = []
        
        init() {
//            fetchPhoto { _returnVal, _error in
//                if let returnVal = _returnVal {
//                    self.photoList = returnVal
//                } else if let error = _error {
//                    print(error)
//                }
//            }
            fetchPhotoAPIClient(completion: { _returnVal, _error in
                if let returnVal = _returnVal {
                    self.photoList = returnVal
                } else if let error = _error {
                    print(error)
                }
            })
        }
        
        func fetchPhoto(completion: @escaping (PhotoList?, Error?) -> Void) {
            //参考 https://zenn.dev/masakatsu_tagi/articles/f5374dd3153bdc
            
            let requestUrl = URL(string: "https://jsonplaceholder.typicode.com/photos?albumId=1")!
            let task = URLSession.shared.dataTask(with: requestUrl) {data, response, error in
                if let error = error {
                    completion(nil, error)
                } else if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let decoded = try decoder.decode(PhotoList.self, from: data)
                        completion(decoded, nil)
                    } catch {
                        print("error")
                    }
                }
            }
            task.resume()
        }
        
        func fetchPhotoAPIClient(completion: @escaping (PhotoList?, Error?) -> Void) {
            let getPhotoRequest = GetPhotosRequest(
                method: HttpMethod.GET,
                parameters: ["albumId":"1"]
            )
            let apiClient = APIClientImpl()
            apiClient.executeWithCompletion (
                getPhotoRequest,
                completion: completion)
        }
    }
}

struct PhotoView : View {
    let photo: Photo
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: photo.thumbnailUrl){ image in
                image.resizable().frame(width: 50, height: 50)
            } placeholder: {
                ProgressView()
            }
            Text("id: \(photo.id)")
            Text("albumId: \(photo.albumId)")
            Text("title: \(photo.title)")
        }
    }
}

//#Preview {
//    PhotoListPageView()
//}

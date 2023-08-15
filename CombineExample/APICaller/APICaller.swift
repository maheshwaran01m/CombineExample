//
//  APICaller.swift
//  CombineExample
//
//  Created by MAHESHWARAN on 07/08/23.
//

import Combine
import Foundation

final class APICaller {
  
  static let shared = APICaller()
  
  var cancelBag = Set<AnyCancellable>()
  
  // MARK: - Fetch News Details
  
  func fetchNews(for searchText: String) -> some Publisher<APIRespone, Error> {
    let urlString = "https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=---Enter-API-Key----"
    
    let search = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    
    guard let url = URL(string: urlString + "&q=\(search)") else {
      return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
    }
    return URLSession
      .shared
      .dataTaskPublisher(for: url)
      .map(\.data)
      .decode(type: APIRespone.self, decoder: customDecoder)
      .eraseToAnyPublisher()
  }
  
  enum NetworkError: Error {
    case invalidURL
  }
  
  let customDecoder: JSONDecoder = {
    var decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
}


// MARK: - Article

struct APIRespone: Codable {
  let articles: [Article]
}

struct Article: Codable {
  var id: String { UUID().uuidString }
  let source: Source
  
  let title: String
  let description: String?
  let url: String?
  let urlToImage: String?
  let publishedAt: String
}

struct Source: Codable {
  let name: String
}

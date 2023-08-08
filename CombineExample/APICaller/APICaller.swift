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
  
  func fetchNews(newsURL: NewsResult) -> some Publisher<APIRespone, Error> {
    guard let url = newsURL.url else {
      return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
    }
    return URLSession
      .shared
      .dataTaskPublisher(for: url)
      .map(\.data)
      .decode(type: APIRespone.self, decoder: customDecoder)
      .eraseToAnyPublisher()
  }
  
  func fetchImageData(_ url: URL) -> some Publisher<Data, Error> {
    return URLSession
      .shared
      .dataTaskPublisher(for: url)
      .map(\.data)
      .decode(type: Data.self, decoder: customDecoder)
  }
  
  // MARK: - NewResult
  
  enum NewsResult {
    case topHeadline
    case business
    case search(Bool, String)
    
    var topHeadlinesURL: String {
      "https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=---Enter-API-Key----"
    }
    
    var businessURL: String {
      "https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=---Enter-API-Key----"
    }
    
    var url: URL? {
      switch self {
      case .topHeadline: return URL(string: topHeadlinesURL)
      case .business: return URL(string: businessURL)
      case .search(let isEnabled, let searchText):
        let search = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: isEnabled ? topHeadlinesURL: businessURL + "&q=\(search)")
      }
    }
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

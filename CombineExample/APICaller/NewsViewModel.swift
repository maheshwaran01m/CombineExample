//
//  NewsViewModel.swift
//  CombineExample
//
//  Created by MAHESHWARAN on 07/08/23.
//

import Foundation
import Combine

class NewsDataModel: Identifiable {
  var id: String { UUID().uuidString }
  
  let title: String
  let subtitle: String
  let imageURL: URL?
  
  init(title: String, subtitle: String, imageURL: URL?) {
    self.title = title
    self.subtitle = subtitle
    self.imageURL = imageURL
  }
}

class NewsViewModel: ObservableObject, Identifiable {
  
  @Published var news: [NewsDataModel] = []
  @Published var searchText = ""
  
  var cancelBag = Set<AnyCancellable>()
  
  var isFromHeadLine = false
  
  init(isFromHeadLine: Bool = false) {
    self.isFromHeadLine = isFromHeadLine
    setupSearch()
  }
  
  func fetchNews(_ newURL: APICaller.NewsResult = .topHeadline) {
    APICaller.shared.fetchNews(newsURL: newURL)
      .map(\.articles)
      .receive(on: DispatchQueue.main)
      .sink {  result in
        switch result {
        case .finished: ()
        case .failure(let error):
          print(error.localizedDescription)
        }
      } receiveValue: { [weak self] news in
        self?.news = news.compactMap {
          .init(title: $0.title, subtitle: $0.description ?? "",
                imageURL: URL(string: $0.urlToImage ?? ""))}
      }
      .store(in: &cancelBag)
  }
  
  func setupSearch() {
    $searchText
      .debounce(for: 0.3, scheduler: DispatchQueue.main)
      .map { $0.lowercased() }
      .map { searchText in
        APICaller.shared.fetchNews(newsURL: .search(self.isFromHeadLine, searchText))
          .replaceError(with: .init(articles: []))
      }
      .switchToLatest()
      .map(\.articles)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { result in
        switch result {
        case .finished: ()
        case .failure(let error):
          print(error.localizedDescription)
        }
      }, receiveValue: { [weak self] news in
        self?.news = news.compactMap {
          .init(title: $0.title, subtitle: $0.description ?? "",
                imageURL: URL(string: $0.urlToImage ?? "")) }
      })
      .store(in: &cancelBag)
  }
}

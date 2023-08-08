//
//  NewsViewModel.swift
//  CombineExample
//
//  Created by MAHESHWARAN on 07/08/23.
//

import Foundation
import Combine

class NewsViewModel: ObservableObject, Identifiable {
  
  @Published var news: [Article] = []
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
        self?.news = news
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
      .assign(to: &$news)
  }
}

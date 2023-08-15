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
  
  init() {
    setupSearch()
  }
  
  func setupSearch() {
    $searchText
      .debounce(for: 0.3, scheduler: DispatchQueue.main)
      .map { $0.lowercased() }
      .map { searchText in
        APICaller.shared.fetchNews(for: searchText)
          .replaceError(with: .init(articles: []))
      }
      .switchToLatest()
      .map(\.articles)
      .receive(on: DispatchQueue.main)
      .assign(to: &$news)
  }
}

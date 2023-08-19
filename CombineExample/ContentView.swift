//
//  ContentView.swift
//  CombineExample
//
//  Created by MAHESHWARAN on 07/08/23.
//

import SwiftUI

struct ContentView: View {
  
  @StateObject private var viewModel = NewsViewModel()
  
  var body: some View {
    NavigationStack {
      ScrollView {
        ForEach(viewModel.news, id: \.id) { item in
          mainView(item)
        }
        .padding(.horizontal, 10)
      }
      .searchable(text: $viewModel.searchText)
      .onSubmit(of: .search, viewModel.setupSearch)
      .navigationTitle("News")
    }
  }
  
  private func mainView(_ item: Article) -> some View {
    HStack(spacing: 10) {
      imageView(item)
      titleView(item)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
  
  @ViewBuilder
  private func imageView(_ item: Article) -> some View {
    AsyncImage(url: URL(string: item.urlToImage ?? "")) { image in
      image
        .resizable()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 100, height: 100)
    } placeholder: {
      
      Image(systemName: "photo.artframe")
        .resizable()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 100, height: 100)
        .foregroundStyle(Color.secondary)
    }
  }
  
  private func titleView(_ item: Article) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(item.title)
        .font(.subheadline)
      
      Text(item.description ?? "")
        .font(.caption)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

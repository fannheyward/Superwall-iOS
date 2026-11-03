//
//  File.swift
//  
//
//  Created by Yusuf Tör on 08/05/2024.
//

import Foundation

struct ManifestDataFetchable: Identifiable {
  var id: String {
    return item.id
  }
  let item: ArchiveManifestItem
  let isMainDocument: Bool
}

struct ManifestDataFetcher: TaskExecutor {
  private let urlSession = URLSession(configuration: .default)

  func perform(using input: ManifestDataFetchable) async throws -> ArchiveManifestItemDownloaded {
    return try await fetchDataForManifest(
      manifest: input.item,
      isMainDocument: input.isMainDocument
    )
  }

  private func fetchDataForManifest(
    manifest: ArchiveManifestItem,
    isMainDocument: Bool
  ) async throws -> ArchiveManifestItemDownloaded {
    let request = URLRequest(
      url: manifest.url,
      cachePolicy: .returnCacheDataElseLoad
    )
    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw ArchivingError.invalidResponse(resource: manifest.url)
    }

    return ArchiveManifestItemDownloaded(
      url: manifest.url,
      mimeType: manifest.mimeType,
      data: data,
      isMainDocument: isMainDocument
    )
  }
}

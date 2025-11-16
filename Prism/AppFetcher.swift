//
//  AppFetcher.swift
//  Prism
//
//  Created by Prayag Chitgupkar on 6/12/25.
//

import Foundation
struct AppFetcher {
    static func getContents(in folder: URL) -> [URL] {
        var items: [URL] = []

        if folder.path == "/Applications" {
            items += fetchAppsAndFolders(in: "/Applications")
            items += fetchAppsAndFolders(in: "/System/Applications")
        } else {
            items += fetchAppsAndFolders(in: folder.path)
        }

        return items.sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() })
    }

    private static func fetchAppsAndFolders(in path: String) -> [URL] {
        let folderURL = URL(fileURLWithPath: path)
        var urls: [URL] = []

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            urls = contents.filter {
                $0.pathExtension == "app" || $0.hasDirectoryPath
            }
        }

        return urls
    }
}

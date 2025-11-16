//
//  screenSizeFetcher.swift
//  Prism
//
//  Created by Prayag Chitgupkar on 6/17/25.
//

import AppKit

public func screenSizeFetcher() -> CGSize {
    guard let screen = NSScreen.main else {
        return .zero
    }
    return screen.frame.size
}

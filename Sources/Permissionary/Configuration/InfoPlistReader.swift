//
//  InfoPlistReader.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Foundation

struct InfoPlistReader: Sendable {
    var string: @Sendable (_ key: String) -> String?

    static let live = InfoPlistReader(
        string: { key in Bundle.main.object(forInfoDictionaryKey: key) as? String }
    )
}

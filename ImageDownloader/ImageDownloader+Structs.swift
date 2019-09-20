//
//  ImageDownloader+Structs.swift
//  ImageDownloader
//
//  Created by Rakesha Shastri on 20/09/19.
//  Copyright © 2019 Rakesha Shastri. All rights reserved.
//

import UIKit

struct ImageDownloadRequest {
    var urlRequest: URLRequest
    var imageID: String
    var size: CGSize? = nil
    var options: ImageDownloadOptions = []
    var subDirectory: String = ""
}

struct ImageDownloadResponse {
    var imageID: String?
    var image: UIImage? = nil
    var source: ImageSource = .cache
}

enum ImageSource {
    case cache
    case documentsDirectory
    case server
}

struct ImageDownloadOptions: OptionSet {
    let rawValue: Int
    
    static let saveInCache = ImageDownloadOptions(rawValue: 1 << 0)
    static let saveInDocumentDirectory = ImageDownloadOptions(rawValue: 1 << 1)
    static let replaceExistingFromServer = ImageDownloadOptions(rawValue: 1 << 2)
}

enum ImageDownloadError: Error {
    case invalidImageData
    case resizingFailed
    case networkError(Error)
}


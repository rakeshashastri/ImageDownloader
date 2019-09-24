//
//  ImageDownloader.swift
//  ImageDownloader
//
//  Created by Rakesha Shastri on 18/09/2019.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit

struct ImageDownloader {
    
    //MARK: - Shared
    static let shared = ImageDownloader()
    
    //MARK: - Private Properties
    private let imageCache = NSCache<NSString, UIImage>()
    private let imageFolderName = "Images"
    private let fileManager = FileManager.default

    //MARK: - Public Methods
    
    /// Get Image from API
    /// - Parameter request: image download request information
    /// - Parameter completion: image download response completion
    func getImage(with request: ImageDownloadRequest, completion: @escaping (Result<ImageDownloadResponse, ImageDownloadError>) -> Void){

        let session = URLSession(configuration: URLSessionConfiguration.default)
        var imageInfo = ImageDownloadResponse(imageID: request.imageID)
        
        // Get image from cache
        if let cachedImage = imageCache.object(forKey: request.imageID as NSString) {
            imageInfo.image = cachedImage
            imageInfo.source = .cache
            if let size = request.size {
                let resizedImage = resize(image: cachedImage, to: size)
                imageInfo.image = resizedImage
            }
            completion(.success(imageInfo))

            // Check if image needs to be updated from server although it is already available in local storage
            if !request.options.contains(.replaceExistingFromServer) {
                return
            }
        }
        
        // Get the image from the documents directory
        if let image = getImageFromDocumentsDirectory(withName: request.imageID), imageInfo.image == nil {
            imageInfo.image = image
            imageInfo.source = .documentsDirectory
            completion(.success(imageInfo))
            
            if request.options.contains(.saveInCache) {
                self.imageCache.setObject(image, forKey: request.imageID as NSString)
            }
            // Check if the image needs to be updated from the server, although it is already available in local storage
            if !request.options.contains(.replaceExistingFromServer) {
                return
            }
        }
        
        let task = session.dataTask(with: request.urlRequest) { (data, response, error) in
            
            // Checking whether error is not nil
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check whether data for the image is not nil
            guard let imageData = data, let image = UIImage(data: imageData) else {
                completion(.failure(ImageDownloadError.invalidImageData))
                return
            }
            
            // Check whether image is already in cache and is the same as the image received from the server
            if let cachedImage = self.imageCache.object(forKey: request.imageID as NSString), cachedImage.pngData() == image.pngData() {
                    return
            } else {
                imageInfo.image = image
                imageInfo.source = .server
                if let size = request.size {
                    let resizedImage = self.resize(image: image, to: size)
                    imageInfo.image = resizedImage
                }
                if request.options.contains(.saveInCache) {
                    self.imageCache.setObject(image, forKey: request.imageID as NSString)
                }
                if request.options.contains(.saveInDocumentDirectory) {
                    self.saveToDocumentsDirectory(image: image, withName: request.imageID)
                }
                completion(.success(imageInfo))
            }
        }
        task.resume()
    }
    
    /// Clear image cache
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    /// Clear images from image directory
    func clearDocumentDirectory() {
        let documentsDirectory = getDocumentsDirectoryForImages()
        do {
            let fileURLS = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            for URL in fileURLS {
                try fileManager.removeItem(at: URL)
            }
        } catch {
            debugPrint(error)
        }
    }
    
    //MARK: - Private Methods
    
    /// Get an image from the documents directory if available
    /// - Parameter name: file name
    private func getImageFromDocumentsDirectory(withName name: String) -> UIImage? {
        let url = getFileURL(for: name)
        debugPrint("Image retreive from \(url.path)")
        return UIImage(contentsOfFile: url.path)
    }
    
    /// Save an image to the documents directory
    /// - Parameter image: image to be stored
    /// - Parameter name: file name
    private func saveToDocumentsDirectory(image: UIImage, withName name: String) {
        let URL = getFileURL(for: name)
        createDirectoryIfItDoesntExist()
        if let imageData = image.jpegData(compressionQuality: 1) {
            do {
                try imageData.write(to: URL)
                debugPrint("Image saved in \(URL.path)")
            } catch {
                debugPrint(error)
            }
        }
    }
    
    /// Create a directory to store if it doesn't exist yet
    /// - Parameter URL: preferred directory URL
    func createDirectoryIfItDoesntExist(withSubDirectory subdirectory: String = "") {
        var directoryURL = getDocumentsDirectoryForImages()
        if !subdirectory.isEmpty {
            directoryURL.appendPathComponent(subdirectory)
        }
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                debugPrint(error)
            }
        }
    }
    
    /// Get the file URL for a particular image file under the folder for storing images
    /// - Parameter fileName: file name
    private func getFileURL(for fileName: String) -> URL {
        let documentsDirectory = getDocumentsDirectoryForImages()
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).jpg")
        return fileURL
    }
    
    /// Get the URL for the document directory holding images
    private func getDocumentsDirectoryForImages() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsDirectory.appendingPathComponent(imageFolderName)
        return folderURL
    }
    
    /// Resize the image
    /// - Parameter image: image to be sized
    /// - Parameter size: size to be resized to
    private func resize(image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
}

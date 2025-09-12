import Foundation
import UIKit

enum ImageStorage {
    static func documentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    // Stored can be: absolute path, file:// URL string, or plain filename.
    static func resolveURL(from stored: String) -> URL? {
        if stored.hasPrefix("/") { return URL(fileURLWithPath: stored) }
        if let url = URL(string: stored), url.isFileURL { return url }
        guard let dir = documentsDirectory() else { return nil }
        return dir.appendingPathComponent(stored)
    }

    static func loadImage(from stored: String) -> UIImage? {
        guard let url = resolveURL(from: stored) else { return nil }
        if let img = UIImage(contentsOfFile: url.path) { return img }
        if let data = try? Data(contentsOf: url) { return UIImage(data: data) }
        return nil
    }
}


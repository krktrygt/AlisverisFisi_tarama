//
//  ReceiptImageDiskManagerTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Testing
import UIKit
@testable import Alisveris_fisTarama

struct ReceiptImageDiskManagerTests {

    private func createTestImageData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50), format: format)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    @Test func testSaveLoadAndDeleteReceiptImage() throws {
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = ReceiptImageDiskManager(fileManager: .default, customBaseURL: tempDirectoryURL)

        defer {
            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        let imageData = createTestImageData()
        #expect(!imageData.isEmpty)

        let filename = "\(UUID().uuidString).jpg"
        let relativePath = try manager.saveReceiptImage(data: imageData, filename: filename)

        #expect(relativePath == "ReceiptImages/\(filename)")

        // Load image back
        let loadedImage = manager.loadReceiptImage(relativePath: relativePath)
        #expect(loadedImage != nil)
        #expect(loadedImage?.size.width == 50)
        #expect(loadedImage?.size.height == 50)

        // Delete image
        try manager.deleteImage(relativePath: relativePath)

        // Confirm it is gone
        let reloadedImage = manager.loadReceiptImage(relativePath: relativePath)
        #expect(reloadedImage == nil)
    }

    @Test func testLoadNonExistentImageReturnsNil() {
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = ReceiptImageDiskManager(fileManager: .default, customBaseURL: tempDirectoryURL)

        defer {
            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        let result = manager.loadReceiptImage(relativePath: "ReceiptImages/non_existent.jpg")
        #expect(result == nil)
    }
}

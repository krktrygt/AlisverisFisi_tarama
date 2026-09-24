//
//  ReceiptImagePreprocessorTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import UIKit
import CoreGraphics
@testable import Alisveris_fisTarama

struct ReceiptImagePreprocessorTests {

    private func createTestReceiptImage() -> UIImage {
        let size = CGSize(width: 200, height: 400)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            // Beyaz termal kağıt zemin
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Metin simülasyonu (siyah çizgiler)
            UIColor.black.setFill()
            context.fill(CGRect(x: 20, y: 30, width: 160, height: 12))
            context.fill(CGRect(x: 20, y: 60, width: 120, height: 10))
            context.fill(CGRect(x: 20, y: 90, width: 140, height: 10))
        }
    }

    @Test func testPreprocessImageSuccess() async throws {
        let preprocessor = ReceiptImagePreprocessor()
        let inputImage = createTestReceiptImage()

        let processedCGImage = try await preprocessor.preprocess(image: inputImage, isFromGallery: false)

        #expect(processedCGImage.width == 200)
        #expect(processedCGImage.height == 400)
    }

    @Test func testPreprocessEmptyImageThrowsError() async {
        let preprocessor = ReceiptImagePreprocessor()
        let emptyImage = UIImage()

        await #expect(throws: Error.self) {
            _ = try await preprocessor.preprocess(image: emptyImage, isFromGallery: false)
        }
    }
}

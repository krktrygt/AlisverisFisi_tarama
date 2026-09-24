//
//  ReceiptImagePreprocessor.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision
import Metal

public final class ReceiptImagePreprocessor: Sendable {
    private let context: CIContext
    
    public init(device: MTLDevice? = nil) {
        if let metalDevice = device ?? MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: metalDevice, options: [
                .useSoftwareRenderer: false,
                .priorityRequestLow: false,
            ])
        } else {
            self.context = CIContext(options: [.useSoftwareRenderer: false])
        }
    }
    
    public func preprocess(image: UIImage, isFromGallery: Bool = false) async throws -> CGImage {
        guard let originalCGImage = image.cgImage else {
            throw NSError(domain: "ReceiptPreprocessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "cgImage alınamadı"])
        }
        
        var ciImage = CIImage(cgImage: originalCGImage)
        
        // 1. Galeri içe aktarımı ise köşe tespiti ve perspektif düzeltme
        if isFromGallery {
            if let corrected = try await detectAndCorrectPerspective(for: ciImage, orientation: image.imageOrientation) {
                ciImage = corrected
            }
        }
        
        // 2. Gri Tonlama (Renk gürültüsünü ve kağıt sararmalarını eler)
        let monoFilter = CIFilter.photoEffectMono()
        monoFilter.inputImage = ciImage
        guard let monoOutput = monoFilter.outputImage else { return originalCGImage }
        
        // 3. Kontrast ve Parlaklık Optimizasyonu
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = monoOutput
        colorControls.contrast = 1.45
        colorControls.brightness = -0.02
        guard let contrastOutput = colorControls.outputImage else { return originalCGImage }
        
        // 4. Nokta Vuruşlu Yazı Keskinleştirme (Unsharp Mask)
        let unsharpFilter = CIFilter.unsharpMask()
        unsharpFilter.inputImage = contrastOutput
        unsharpFilter.radius = 2.2
        unsharpFilter.intensity = 0.65
        guard let sharpenedOutput = unsharpFilter.outputImage else { return originalCGImage }
        
        // 5. Metal GPU Context üzerinden CGImage üretimi
        guard let resultCG = context.createCGImage(sharpenedOutput, from: sharpenedOutput.extent) else {
            return originalCGImage
        }
        return resultCG
    }
    
    // MARK: - Perspektif Düzeltme (Galeri Görselleri İçin)
    
    private func detectAndCorrectPerspective(for image: CIImage, orientation: UIImage.Orientation) async throws -> CIImage? {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { req, err in
                if let err = err {
                    continuation.resume(throwing: err)
                    return
                }
                guard let results = req.results as? [VNRectangleObservation], let rect = results.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let extent = image.extent
                let filter = CIFilter.perspectiveCorrection()
                filter.inputImage = image
                filter.topLeft = CGPoint(x: rect.topLeft.x * extent.width, y: rect.topLeft.y * extent.height)
                filter.topRight = CGPoint(x: rect.topRight.x * extent.width, y: rect.topRight.y * extent.height)
                filter.bottomLeft = CGPoint(x: rect.bottomLeft.x * extent.width, y: rect.bottomLeft.y * extent.height)
                filter.bottomRight = CGPoint(x: rect.bottomRight.x * extent.width, y: rect.bottomRight.y * extent.height)
                continuation.resume(returning: filter.outputImage)
            }
            request.minimumConfidence = 0.65
            request.maximumAspectRatio = 1.0
            request.minimumAspectRatio = 0.15
            
            let cgOrientation = self.mapCGImagePropertyOrientation(from: orientation)
            let handler = VNImageRequestHandler(ciImage: image, orientation: cgOrientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - UIImage.Orientation -> CGImagePropertyOrientation Eşlemesi

        private func mapCGImagePropertyOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
            switch uiOrientation {
            case .up: return .up
            case .upMirrored: return .upMirrored
            case .down: return .down
            case .downMirrored: return .downMirrored
            case .left: return .left
            case .leftMirrored: return .leftMirrored
            case .right: return .right
            case .rightMirrored: return .rightMirrored
            @unknown default: return .up
            }
        }
}

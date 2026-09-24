//
//  DocumentScannerView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import SwiftUI
import VisionKit
import PhotosUI

public struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding public var isPresented: Bool
    public var onScanCompleted: ([UIImage]) -> Void
    public var onScanFailed: (String) -> Void
    public var onScanCancelled: () -> Void

    public init(
        isPresented: Binding<Bool>,
        onScanCompleted: @escaping ([UIImage]) -> Void,
        onScanFailed: @escaping (String) -> Void,
        onScanCancelled: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.onScanCompleted = onScanCompleted
        self.onScanFailed = onScanFailed
        self.onScanCancelled = onScanCancelled
    }

    public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        if VNDocumentCameraViewController.isSupported {
            let scanner = VNDocumentCameraViewController()
            scanner.delegate = context.coordinator
            return scanner
        } else {
            // Simülatör veya kamera desteklenmeyen ortamlar için PHPickerViewController fallback'i
            var config = PHPickerConfiguration()
            config.selectionLimit = 10
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // SwiftUI State güncellendiğinde yapılacak bir işlem yoksa boş bırakılır.
    }

    // MARK: - UIKit & VisionKit & PhotosUI Delegate Köprüsü (Coordinator)
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate, PHPickerViewControllerDelegate {
        private let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        // MARK: - VNDocumentCameraViewControllerDelegate (Fiziksel Cihaz)

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var scannedImages: [UIImage] = []
            scannedImages.reserveCapacity(scan.pageCount)

            for pageIndex in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: pageIndex))
            }

            parent.isPresented = false
            parent.onScanCompleted(scannedImages)
        }

        public func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            parent.isPresented = false
            parent.onScanCancelled()
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.isPresented = false
            parent.onScanFailed(error.localizedDescription)
        }

        // MARK: - PHPickerViewControllerDelegate (Simülatör Fallback)

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                parent.isPresented = false
                parent.onScanCancelled()
                return
            }

            let group = DispatchGroup()
            var loadedImages: [UIImage] = []
            let lock = NSLock()

            for result in results {
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        if let uiImage = image as? UIImage {
                            lock.lock()
                            loadedImages.append(uiImage)
                            lock.unlock()
                        }
                    }
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                self.parent.isPresented = false
                if loadedImages.isEmpty {
                    self.parent.onScanFailed("Görsel yüklenemedi.")
                } else {
                    self.parent.onScanCompleted(loadedImages)
                }
            }
        }
    }
}

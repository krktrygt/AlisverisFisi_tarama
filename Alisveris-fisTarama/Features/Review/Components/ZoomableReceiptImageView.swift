//
//  ZoomableReceiptImageView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI

public struct ZoomableReceiptImageView: View {
    public let image: UIImage?
    public let activeBoundingBox: NormalizedRect?

    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero

    public init(image: UIImage?, activeBoundingBox: NormalizedRect?) {
        self.image = image
        self.activeBoundingBox = activeBoundingBox
    }

    public var body: some View {
        GeometryReader { proxy in
            let viewSize = proxy.size

            ZStack {
                Color(.secondarySystemBackground)

                if let uiImage = image {
                    let imgSize = uiImage.size
                    let s = min(viewSize.width / max(imgSize.width, 1), viewSize.height / max(imgSize.height, 1))
                    let displayedWidth = imgSize.width * s
                    let displayedHeight = imgSize.height * s
                    let deltaX = (viewSize.width - displayedWidth) / 2
                    let deltaY = (viewSize.height - displayedHeight) / 2

                    ZStack(alignment: .topLeading) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: displayedWidth, height: displayedHeight)

                        // Aktif Bounding Box Kutucuğu
                        if let box = activeBoundingBox {
                            let rectX = box.originX * displayedWidth
                            let rectY = box.originY * displayedHeight
                            let rectW = box.width * displayedWidth
                            let rectH = box.height * displayedHeight

                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.orange, lineWidth: 2)
                                .background(Color.orange.opacity(0.2))
                                .frame(width: max(rectW, 10), height: max(rectH, 10))
                                .offset(x: rectX, y: rectY)
                        }
                    }
                    .frame(width: displayedWidth, height: displayedHeight)
                    .offset(x: deltaX - (viewSize.width - displayedWidth) / 2, y: deltaY - (viewSize.height - displayedHeight) / 2)
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                currentScale = max(1.0, min(value, 4.0))
                            }
                            .onEnded { _ in
                                if currentScale < 1.0 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        currentScale = 1.0
                                        currentOffset = .zero
                                    }
                                }
                            }
                    )
                    .onChange(of: activeBoundingBox) { _, newBox in
                        guard let box = newBox else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentScale = 1.0
                                currentOffset = .zero
                            }
                            return
                        }
                        // Dokun-incele odaklama: Kutucuğun merkezini hesaplayıp 2x zoom ile ekrana ortala
                        let boxCenterX = (box.originX + box.width / 2) * displayedWidth
                        let boxCenterY = (box.originY + box.height / 2) * displayedHeight
                        let targetOffsetX = (displayedWidth / 2 - boxCenterX) * 1.5
                        let targetOffsetY = (displayedHeight / 2 - boxCenterY) * 1.5

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentScale = 2.0
                            currentOffset = CGSize(width: targetOffsetX, height: targetOffsetY)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.image")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Fiş görseli bulunamadı")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .clipped()
        }
    }
}

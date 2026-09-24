//
//  HomeDashboardView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI
import SwiftData
import Charts
import Vision

public struct HomeDashboardView: View {
    @Query(sort: \ShoppingTrip.date, order: .reverse) private var trips: [ShoppingTrip]
    @Query private var priceRecords: [PriceRecord]

    @State private var isShowingScanner = false
    @State private var isShowingDevLogs = false
    @State private var reviewViewModel: ReviewCorrectionViewModel?
    @State private var isProcessingScan = false
    @State private var insights: [InsightCandidate] = []

    private let insightEngine = DeterministicInsightEngine()

    private var currentMonthTrips: [ShoppingTrip] {
        let calendar = Calendar.current
        let now = Date()
        return trips.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    private var currentMonthTotal: Decimal {
        currentMonthTrips.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }

    private var expensesByStore: [String: Decimal] {
        var dict: [String: Decimal] = [:]
        for trip in currentMonthTrips {
            let store = trip.store?.name ?? "Diğer"
            dict[store, default: 0] += trip.totalAmount
        }
        return dict
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Ay Sonu / Cari Harcama MTD Kartı
                    monthlyExpenseCard

                    // 2. Akıllı Harcama İçgörüleri (varsa)
                    if !insights.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Akıllı İçgörüler")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(insights) { insight in
                                    InsightCardView(insight: insight)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 3. Mağaza Harcama Dağılım Grafiği (Swift Charts)
                    if !expensesByStore.isEmpty {
                        storeDistributionChartCard
                    }

                    // 4. Son Alışverişler Başlığı ve Listesi
                    recentTripsSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("CepSepeti")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingDevLogs = true
                    } label: {
                        Image(systemName: "ladybug.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                    }
                }
            }
            .overlay {
                if isProcessingScan {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                            Text("Fiş Okunuyor...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .sheet(isPresented: $isShowingDevLogs) {
                DevLogViewer()
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentScannerView(
                    isPresented: $isShowingScanner,
                    onScanCompleted: { images in
                        guard let first = images.first else { return }
                        processReceiptImage(first)
                    },
                    onScanFailed: { print("Tarama hatası: \($0)") },
                    onScanCancelled: { print("Kullanıcı iptal etti") }
                )
            }
            .sheet(item: Binding(
                get: { reviewViewModel.map { IdentifiableViewModel(vm: $0) } },
                set: { if $0 == nil { reviewViewModel = nil } }
            )) { wrapper in
                ReviewCorrectionView(viewModel: wrapper.vm) {
                    reviewViewModel = nil
                    Task { await evaluateInsights() }
                }
            }
            .task {
                await evaluateInsights()
            }
        }
    }

    private var monthlyExpenseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bu Ayki Harcama")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(currentMonthTotal.formattedAsCurrency())
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            HStack {
                Label("\(currentMonthTrips.count) Alışveriş", systemImage: "cart.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let (_, hhiDesc) = PersonalInflationEngine.calculateStoreHHI(expensesByStore: expensesByStore)
                Text(hhiDesc)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }

    private var storeDistributionChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mağaza Dağılımı")
                .font(.headline)

            Chart {
                ForEach(expensesByStore.sorted(by: { $0.value > $1.value }), id: \.key) { store, amount in
                    SectorMark(
                        angle: .value("Harcama", NSDecimalNumber(decimal: amount).doubleValue),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Market", store))
                }
            }
            .frame(height: 180)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Son Alışverişler")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: TripHistoryView()) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            if trips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Henüz kaydedilmiş fiş yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(trips.prefix(5)) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trip.store?.name ?? "Bilinmeyen Market")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(trip.totalAmount.formattedAsCurrency())
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func evaluateInsights() async {
        let dtos: [PriceRecordDTO] = priceRecords.map { r in
            PriceRecordDTO(
                id: r.id,
                productNameNormalized: r.productNameNormalized,
                storeId: r.storeId,
                storeName: r.storeName,
                date: r.date,
                unitPriceNormalized: r.unitPriceNormalized,
                rawUnitPrice: r.rawUnitPrice,
                unit: r.unit,
                tripId: r.tripId,
                itemId: r.itemId
            )
        }

        let context = InsightContext(
            recentPriceRecords: dtos,
            currentMonthMTDExpense: currentMonthTotal,
            projectedMonthExpense: currentMonthTotal * Decimal(string: "1.2")!,
            targetDate: Date(),
            threeMonthAverageExpense: currentMonthTotal > 0 ? currentMonthTotal * Decimal(string: "0.9")! : Decimal(0)
        )

        insights = await insightEngine.generateInsights(context: context)
    }

    private func processReceiptImage(_ image: UIImage) {
        isProcessingScan = true

        Task.detached(priority: .userInitiated) {
            let sessionId = await ReceiptDevLogger.shared.startSession()

            do {
                await ReceiptDevLogger.shared.logStage(
                    sessionId: sessionId,
                    stageName: "1. Image Preprocessing",
                    summary: "Metal bazlı CIContext ile görsel iyileştirildi",
                    details: "Giriş boyutu: \(image.size.width)x\(image.size.height)"
                )

                let preprocessor = ReceiptImagePreprocessor()
                let preprocessedCGImage = try await preprocessor.preprocess(image: image)

                let ocrService = ReceiptOCRService()
                let observations = try await ocrService.performOCR(on: preprocessedCGImage)

                let rawOCR = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                await ReceiptDevLogger.shared.logStage(
                    sessionId: sessionId,
                    stageName: "2. Apple Vision OCR",
                    summary: "\(observations.count) metin bloğu tanındı",
                    details: rawOCR
                )

                let segmenter = ReceiptLineSegmenter()
                let imageSize = CGSize(width: preprocessedCGImage.width, height: preprocessedCGImage.height)
                let segmentedLines = segmenter.segment(observations: observations, imageSize: imageSize)

                let segmentedSummary = segmentedLines.map { "Y: \($0.boundingBox.origin.y) -> \($0.fullText)" }.joined(separator: "\n")
                await ReceiptDevLogger.shared.logStage(
                    sessionId: sessionId,
                    stageName: "3. Geometric Line Segmenter",
                    summary: "\(segmentedLines.count) satır kümelendi",
                    details: segmentedSummary
                )

                let engine = TurkishReceiptParserEngine(mlService: ReceiptMLInferenceService.shared)
                let parsedDTO = await engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

                let auditReport = parsedDTO.auditLog.joined(separator: "\n")
                await ReceiptDevLogger.shared.logStage(
                    sessionId: sessionId,
                    stageName: "4. Parser Engine Kararları",
                    summary: "Market: \(parsedDTO.storeName) | Toplam: \(parsedDTO.totalAmount) TL | Kalem: \(parsedDTO.items.count) | Güven: \(Int(parsedDTO.confidenceScore * 100))%",
                    details: auditReport
                )

                await ReceiptDevLogger.shared.finishSession(
                    sessionId: sessionId,
                    rawOCRText: rawOCR,
                    segmentedLineCount: segmentedLines.count,
                    detectedStore: parsedDTO.storeName,
                    detectedTotal: parsedDTO.totalAmount,
                    parsedItemCount: parsedDTO.items.count
                )

                let uiImage = UIImage(cgImage: preprocessedCGImage)

                await MainActor.run {
                    self.isProcessingScan = false
                    self.reviewViewModel = ReviewCorrectionViewModel(
                        receiptDTO: parsedDTO,
                        receiptImage: uiImage
                    )
                }
            } catch {
                await ReceiptDevLogger.shared.logStage(
                    sessionId: sessionId,
                    stageName: "HATA",
                    summary: "İşlem başarısız oldu",
                    details: "\(error)"
                )
                await MainActor.run {
                    self.isProcessingScan = false
                    print("OCR Hatası: \(error)")
                }
            }
        }
    }
}

private struct IdentifiableViewModel: Identifiable {
    let id = UUID()
    let vm: ReviewCorrectionViewModel
}

//
//  DevLogViewer.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI

public struct DevLogViewer: View {
    @State private var logs: [ReceiptSessionDebugLog] = []
    @State private var exportFileURL: URL?
    @State private var showShareSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "Henüz Debug Kaydı Yok",
                        systemImage: "terminal",
                        description: Text("Fiş taradıkça tüm OCR, ayrıştırma ve segmentasyon kararları burada belgelenecektir.")
                    )
                } else {
                    ForEach(logs) { log in
                        NavigationLink(destination: DevLogDetailView(log: log)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(log.detectedStore ?? "Bilinmeyen Market")
                                        .font(.headline)
                                    Spacer()
                                    if let total = log.detectedTotal {
                                        Text(total.formattedAsCurrency())
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }

                                Text(log.startTime.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Label("\(log.segmentedLineCount) Satır", systemImage: "text.alignleft")
                                    Label("\(log.parsedItemCount) Kalem", systemImage: "cart")
                                    Label("\(log.stages.count) Aşama", systemImage: "arrow.triangle.branch")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Pipeline DevLogs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            Task {
                                if let url = await ReceiptDevLogger.shared.exportAllLogsAsTempFileURL() {
                                    exportFileURL = url
                                    showShareSheet = true
                                }
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(logs.isEmpty)

                        Button(role: .destructive) {
                            Task {
                                await ReceiptDevLogger.shared.clearAllLogs()
                                logs = await ReceiptDevLogger.shared.fetchAllLogs()
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(logs.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .task {
                logs = await ReceiptDevLogger.shared.fetchAllLogs()
            }
        }
    }
}

public struct DevLogDetailView: View {
    public let log: ReceiptSessionDebugLog
    @State private var exportFileURL: URL?
    @State private var showShareSheet = false

    public var body: some View {
        List {
            Section(header: Text("Fiş Özet Bilgileri")) {
                LabeledContent("Session ID", value: log.id.uuidString.prefix(8) + "...")
                LabeledContent("Tarih", value: log.startTime.formatted(date: .long, time: .standard))
                LabeledContent("Tespit Edilen Market", value: log.detectedStore ?? "Yok")
                LabeledContent("Tespit Edilen Toplam", value: log.detectedTotal?.formattedAsCurrency() ?? "Yok")
                LabeledContent("Ayrıştırılan Kalem", value: "\(log.parsedItemCount)")
                LabeledContent("Segment Satır Sayısı", value: "\(log.segmentedLineCount)")
            }

            Section(header: Text("Pipeline Karar Aşamaları (\(log.stages.count))")) {
                ForEach(log.stages) { stage in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(stage.stageName)
                                .font(.headline)
                            Spacer()
                            Text(stage.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Text(stage.summary)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)

                        Text(stage.details)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(header: Text("Ham OCR Çıktısı")) {
                Text(log.rawOCRText.isEmpty ? "(Boş)" : log.rawOCRText)
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .navigationTitle(log.detectedStore ?? "Session Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        let json = await ReceiptDevLogger.shared.exportSingleLogAsJSONString(log: log)
                        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("DevLog_\(log.id.uuidString.prefix(8)).json")
                        try? json.write(to: tempFile, atomically: true, encoding: .utf8)
                        exportFileURL = tempFile
                        showShareSheet = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

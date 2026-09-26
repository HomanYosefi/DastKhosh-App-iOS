//
//  SettingsScreen.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI
import Swinject
import UniformTypeIdentifiers

struct SettingsScreen: View {
    let onNavigateBack: () -> Void
    @StateObject private var viewModel: SettingsViewModel

    init(onNavigateBack: @escaping () -> Void) {
        self.onNavigateBack = onNavigateBack

        let container = DependencyContainer.shared.container
        let manager = container.resolve(BackupManager.self)!
        let repo = container.resolve(ExpenseRepository.self)!
        _viewModel = StateObject(wrappedValue: SettingsViewModel(backupManager: manager, repository: repo))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("پشتیبان‌گیری از اطلاعات")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("می‌توانید اطلاعات خود را در قالب یک فایل ذخیره کنید یا اطلاعات قبلی را بازگردانید.")
                        .font(.body)
                        .foregroundColor(AppTheme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Spacer().frame(height: 20)

                Button(action: { viewModel.prepareExport() }) {
                    Text("تهیه فایل پشتیبان (بکاپ)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.primary)
                        .cornerRadius(18)
                }
                .buttonStyle(BouncyButtonStyle())

                Button(action: { viewModel.isImporting = true }) {
                    Text("بازگردانی اطلاعات (ایمپورت)")
                        .font(.headline)
                        .foregroundColor(AppTheme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppTheme.primary, lineWidth: 1.5)
                        )
                }
                .buttonStyle(BouncyButtonStyle())

                Spacer()
            }
            .padding(24)
            .navigationTitle("تنظیمات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onNavigateBack) {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.primary)
                    }
                }
            }
            .fileExporter(
                isPresented: $viewModel.isExporting,
                document: viewModel.backupDocument,
                contentType: .json,
                defaultFilename: "dastkhosh_backup.json"
            ) { result in
                switch result {
                case .success:
                    viewModel.alertMessage = "بکاپ با موفقیت ذخیره شد!"
                case .failure:
                    viewModel.alertMessage = "خطا در ذخیره فایل بکاپ!"
                }
            }
            .fileImporter(
                isPresented: $viewModel.isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let urls = try result.get()
                    if let selectedUrl = urls.first {
                        let _ = selectedUrl.startAccessingSecurityScopedResource()
                        viewModel.handleImportResult(.success(selectedUrl))
                        selectedUrl.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    viewModel.handleImportResult(.failure(error))
                }
            }
            .alert(
                viewModel.alertMessage ?? "",
                isPresented: Binding(
                    get: { viewModel.alertMessage != nil },
                    set: { if !$0 { viewModel.alertMessage = nil } }
                )
            ) {
                Button("تایید", role: .cancel) {}
            }
        }
    }
}

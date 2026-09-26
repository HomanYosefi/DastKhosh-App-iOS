//
//  SettingsViewModel.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    private let backupManager: BackupManager
    private let repository: ExpenseRepository

    @Published var alertMessage: String?
    @Published var backupDocument: JSONBackupDocument?
    @Published var isExporting = false
    @Published var isImporting = false

    init(backupManager: BackupManager, repository: ExpenseRepository) {
        self.backupManager = backupManager
        self.repository = repository
    }

    func prepareExport() {
        Task {
            do {
                let expenses = try await repository.getAllExpensesSync()
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(expenses)
                self.backupDocument = JSONBackupDocument(jsonData: data)
                self.isExporting = true
            } catch {
                self.alertMessage = "خطا در آماده‌سازی بکاپ!"
            }
        }
    }

    func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task {
                let outcome = await backupManager.importBackup(from: url)
                switch outcome {
                case .success:
                    self.alertMessage = "اطلاعات با موفقیت بازگردانی شد!"
                case .failure:
                    self.alertMessage = "فایل نامعتبر است یا خطا در بازگردانی!"
                }
            }
        case .failure:
            self.alertMessage = "خطا در انتخاب فایل!"
        }
    }
}

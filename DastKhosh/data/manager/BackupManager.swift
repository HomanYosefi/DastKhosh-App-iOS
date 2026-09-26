//
//  BackupManager.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation

final class BackupManager {
    private let repository: ExpenseRepository
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(repository: ExpenseRepository) {
        self.repository = repository
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = .prettyPrinted
        self.decoder = JSONDecoder()
    }

    func exportBackup(to fileURL: URL) async -> Result<Void, Error> {
        do {
            let expenses = try await repository.getAllExpensesSync()
            let jsonData = try encoder.encode(expenses)
            try jsonData.write(to: fileURL, options: .atomic)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func importBackup(from fileURL: URL) async -> Result<Void, Error> {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let expenses = try decoder.decode([Expense].self, from: jsonData)
            try await repository.insertExpenses(expenses)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

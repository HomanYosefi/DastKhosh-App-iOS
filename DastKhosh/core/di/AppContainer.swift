//
//  AppContainer.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import Swinject
import SwiftData

final class DependencyContainer {
    static let shared = DependencyContainer()
    let container = Container()

    @MainActor
    func setupDependencies() {
        // SwiftData Container
        container.register(ModelContainer.self) { _ in
            do {
                let schema = Schema([ExpenseEntity.self])
                return try ModelContainer(for: schema)
            } catch {
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }.inObjectScope(.container)

        // Repository
        container.register(ExpenseRepository.self) { resolver in
            let modelContainer = resolver.resolve(ModelContainer.self)!
            return ExpenseRepositoryImpl(modelContainer: modelContainer)
        }.inObjectScope(.container)

        // Backup Manager
        container.register(BackupManager.self) { resolver in
            let repository = resolver.resolve(ExpenseRepository.self)!
            return BackupManager(repository: repository)
        }.inObjectScope(.container)

        // Use Cases
        container.register(GetAllExpensesUseCase.self) { resolver in
            let repo = resolver.resolve(ExpenseRepository.self)!
            return GetAllExpensesUseCase(repository: repo)
        }

        container.register(InsertExpenseUseCase.self) { resolver in
            let repo = resolver.resolve(ExpenseRepository.self)!
            return InsertExpenseUseCase(repository: repo)
        }

        container.register(DeleteExpenseUseCase.self) { resolver in
            let repo = resolver.resolve(ExpenseRepository.self)!
            return DeleteExpenseUseCase(repository: repo)
        }
    }
}

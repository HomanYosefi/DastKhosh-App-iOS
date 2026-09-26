//
//  DastkhoshAppView.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI
import Swinject

struct DastkhoshAppView: View {
    @StateObject private var viewModel: ExpenseViewModel
    @State private var currentScreen: Screen = .addExpense
    @State private var snackbarText: String?
    @State private var canUndo: Bool = false

    init() {
        let container = DependencyContainer.shared.container
        let vm = ExpenseViewModel(
            insertExpenseUseCase: container.resolve(InsertExpenseUseCase.self)!,
            getAllExpensesUseCase: container.resolve(GetAllExpensesUseCase.self)!,
            deleteExpenseUseCase: container.resolve(DeleteExpenseUseCase.self)!
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch currentScreen {
                case .addExpense:
                    AddExpenseScreen(viewModel: viewModel)
                case .history:
                    ExpenseHistoryScreen(
                        viewModel: viewModel,
                        onNavigateToSettings: {
                            withAnimation { currentScreen = .settings }
                        }
                    )
                case .settings:
                    SettingsScreen(
                        onNavigateBack: {
                            withAnimation { currentScreen = .history }
                        }
                    )
                }
            }   
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let text = snackbarText {
                HStack {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    if canUndo {
                        Button("بازگردانی") {
                            viewModel.undoDelete()
                            withAnimation { snackbarText = nil }
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.primaryContainer)
                    }
                }
                .padding()
                .background(Color(uiColor: .darkGray))
                .cornerRadius(18)
                .padding(.horizontal, 20)
                .padding(.bottom, 96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            FloatingNavBar(
                items: Screen.items,
                currentScreen: currentScreen,
                onSelect: { screen in
                    withAnimation { currentScreen = screen }
                }
            )
        }
        .environment(\.layoutDirection, .rightToLeft) 
        .onReceive(viewModel.events) { event in
            withAnimation {
                switch event {
                case .message(let text):
                    self.snackbarText = text
                    self.canUndo = false
                case .deleted(let text):
                    self.snackbarText = text
                    self.canUndo = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation { self.snackbarText = nil }
            }
        }
    }
}

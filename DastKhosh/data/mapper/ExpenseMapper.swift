//
//  ExpenseMapper.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation

extension ExpenseEntity {
    func toDomain() -> Expense {
        Expense(
            id: self.id,
            amount: self.amount,
            description: self.expenseDescription,
            createdAt: self.createdAt
        )
    }
}

extension Expense {
    func toEntity() -> ExpenseEntity {
        ExpenseEntity(
            id: self.id == 0 ? Int64(Date().timeIntervalSince1970 * 1000) : self.id,
            amount: self.amount,
            expenseDescription: self.description,
            createdAt: self.createdAt
        )
    }
}

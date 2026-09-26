//
//  ExpenseEntity.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import SwiftData

@Model
final class ExpenseEntity {
    @Attribute(.unique) var id: Int64
    var amount: Int64
    var expenseDescription: String
    var createdAt: Int64

    init(id: Int64 = 0, amount: Int64, expenseDescription: String, createdAt: Int64) {
        self.id = id
        self.amount = amount
        self.expenseDescription = expenseDescription
        self.createdAt = createdAt
    }
}

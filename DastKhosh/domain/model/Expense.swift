//
//  Expense.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation

struct Expense: Identifiable, Codable, Equatable {
    var id: Int64
    let amount: Int64
    let description: String
    let createdAt: Int64

    init(
        id: Int64 = 0,
        amount: Int64,
        description: String,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.amount = amount
        self.description = description
        self.createdAt = createdAt
    }
}

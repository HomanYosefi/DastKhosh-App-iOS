//
//  ExpenseFormState.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//
import Foundation

struct ExpenseFormState {
    var amount = ""
    var description = ""
    var amountError: String?
    var descriptionError: String?
    var isSaving = false
    var errorTick = 0
    var savedTick = 0

    var amountValue: Int64 {
        Int64(amount) ?? 0
    }

    var isValid: Bool {
        amountValue > 0 &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

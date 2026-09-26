//
//  ChartData.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//
import SwiftUI
import Foundation

struct ChartData: Identifiable , Equatable {
    var id: String { label }

    let label: String
    let amount: Int64
    let percentage: Float
    let color: Color
}

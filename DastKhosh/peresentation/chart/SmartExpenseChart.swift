//
//  SmartExpenseChart.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI

// MARK: - Smart Chart Wrapper
struct SmartExpenseChart: View {
    let timeFilter: TimeFilter
    let chartData: [ChartData]
    let totalAmount: Int64

    var body: some View {
        if !chartData.isEmpty {
            VStack(alignment: .center, spacing: 16) {
                if timeFilter == .daily {
                    AnimatedDonutChart(chartData: chartData, totalAmount: totalAmount)
                    ChartLegend(chartData: chartData)
                } else {
                    AnimatedBarChart(chartData: chartData, totalAmount: totalAmount)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Donut Chart
struct AnimatedDonutChart: View {
    let chartData: [ChartData]
    let totalAmount: Int64
    var chartSize: CGFloat = 200
    var strokeWidth: CGFloat = 26

    @State private var animateSweep: CGFloat = 0

    var body: some View {
        ZStack {
            ZStack {
                var accumulatedAngle: Double = -90.0

                ForEach(chartData) { data in
                    let sweepAngle = Double(data.percentage) * 360.0 * Double(animateSweep)
                    let start = accumulatedAngle
                    let _ = { accumulatedAngle += sweepAngle }()

                    DonutArc(
                        startAngle: .degrees(start),
                        endAngle: .degrees(start + sweepAngle)
                    )
                    .stroke(data.color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    .frame(width: chartSize - strokeWidth, height: chartSize - strokeWidth)
                }
            }
            .frame(width: chartSize, height: chartSize)

            VStack(spacing: 4) {
                Text("جمع کل")
                    .font(.caption)
                    .foregroundColor(AppTheme.onSurfaceVariant)

                Text(totalAmount.toMoney())
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.primary)

                Text("تومان")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.onSurfaceVariant)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animateSweep = 1.0
            }
        }
        .onChange(of: chartData) { _, _ in
            animateSweep = 0.0
            withAnimation(.easeInOut(duration: 1.2)) {
                animateSweep = 1.0
            }
        }
    }
}

private struct DonutArc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard endAngle > startAngle else { return path }
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

// MARK: - Legend
struct ChartLegend: View {
    let chartData: [ChartData]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(chartData) { data in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(data.color)
                            .frame(width: 10, height: 10)

                        Text(data.label)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Bar Chart
struct AnimatedBarChart: View {
    let chartData: [ChartData]
    let totalAmount: Int64

    @State private var animateHeight: CGFloat = 0

    private let maxBarHeight: CGFloat = 140
    private let barWidth: CGFloat = 38

    private var maxAmount: Int64 {
        chartData.map(\.amount).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("مجموع هزینه‌ها")
                    .font(.caption)
                    .foregroundColor(AppTheme.onSurfaceVariant)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(totalAmount.toMoney())
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(AppTheme.primary)

                    Text("تومان")
                        .font(.caption)
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }
            }

            ZStack(alignment: .bottom) {
                Divider()
                    .offset(y: -30)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 22) {
                        ForEach(chartData) { data in
                            let ratio = CGFloat(data.amount) / CGFloat(maxAmount)
                            let currentHeight = max(ratio * maxBarHeight * animateHeight, 6)

                            VStack(spacing: 8) {
                                Text(data.amount.toShortToman().replacingOccurrences(of: " تومان", with: ""))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.onSurfaceVariant)

                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.surfaceVariant.opacity(0.4))
                                        .frame(width: barWidth, height: maxBarHeight)

                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [data.color.opacity(0.7), data.color],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: barWidth, height: currentHeight)
                                }

                                Text(data.label)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .frame(width: 56)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(height: 240)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animateHeight = 1.0
            }
        }
        .onChange(of: chartData) { _, _ in
            animateHeight = 0.0
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animateHeight = 1.0
            }
        }
    }
}

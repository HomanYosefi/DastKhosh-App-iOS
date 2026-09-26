//
//  FloatingNavBar.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI

struct FloatingNavBar: View {
    let items: [Screen]
    let currentScreen: Screen
    let onSelect: (Screen) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { screen in
                NavBarItem(
                    screen: screen,
                    isSelected: currentScreen == screen,
                    onClick: { onSelect(screen) }
                )
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 64)
        .background(AppTheme.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
}

private struct NavBarItem: View {
    let screen: Screen
    let isSelected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                Image(systemName: screen.iconName)
                    .font(.system(size: 18, weight: .bold))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isSelected)

                if isSelected {
                    Text(screen.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .foregroundColor(isSelected ? AppTheme.onPrimary : AppTheme.onSurfaceVariant)
            .padding(.horizontal, isSelected ? 18 : 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.primary : Color.clear)
            )
            .animation(.spring(response: 0.38, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

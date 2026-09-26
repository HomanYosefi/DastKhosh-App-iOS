//
//  AddExpenseScreen.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI

enum FormStep {
    case amount
    case description
}

struct AddExpenseScreen: View {
    @ObservedObject var viewModel: ExpenseViewModel

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var currentStep: FormStep = .amount
    @State private var shakeTrigger = 0
    @State private var showSuccess = false
    @State private var localAmountError: String?

    private enum InputField: Hashable {
        case amount
        case description
    }

    @FocusState private var focusedField: InputField?

    private let quickAmounts: [Int64] = [
        10_000,
        50_000,
        100_000,
        500_000,
        1_000_000
    ]

    private let chipColumns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    private var amountError: String? {
        localAmountError ?? viewModel.formState.amountError
    }

    private var stepAnimation: Animation {
        reduceMotion
        ? .easeInOut(duration: 0.15)
        : .spring(response: 0.45, dampingFraction: 0.86)
    }

    var body: some View {
        GeometryReader { geometry in
            screenContent(topInset: geometry.safeAreaInsets.top)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func screenContent(topInset: CGFloat) -> some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    GradientHeader(
                        total: viewModel.total,
                        topInset: topInset
                    )
                    VStack(spacing: 22) {
                        stepIndicator

                        ZStack(alignment: .top) {
                            if currentStep == .amount {
                                amountStepView
                                    .transition(
                                        reduceMotion
                                        ? .opacity
                                        : .asymmetric(
                                            insertion: .move(edge: .trailing)
                                                .combined(with: .opacity),
                                            removal: .move(edge: .trailing)
                                                .combined(with: .opacity)
                                        )
                                    )
                            } else {
                                descriptionStepView
                                    .transition(
                                        reduceMotion
                                        ? .opacity
                                        : .asymmetric(
                                            insertion: .move(edge: .leading)
                                                .combined(with: .opacity),
                                            removal: .move(edge: .leading)
                                                .combined(with: .opacity)
                                        )
                                    )
                            }
                        }
                        .animation(stepAnimation, value: currentStep)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }
        
            .ignoresSafeArea(.container, edges: .top)
            .scrollDismissesKeyboard(.interactively)
            .disabled(viewModel.formState.isSaving || showSuccess)
            .accessibilityHidden(showSuccess)
            .scrollDismissesKeyboard(.interactively)
            .disabled(viewModel.formState.isSaving || showSuccess)
            .accessibilityHidden(showSuccess)

            if showSuccess {
                SuccessOverlay()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .foregroundStyle(AppTheme.onSurface)
        .tint(AppTheme.primary)
        .environment(\.layoutDirection, .rightToLeft)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("تمام") {
                    focusedField = nil
                }
            }
        }
        .onChange(of: viewModel.formState.amount) { _, _ in
            localAmountError = nil
        }
        .onChange(of: viewModel.formState.errorTick) { _, tick in
            guard tick > 0 else { return }

            viewModel.consumeErrorTick()

            if viewModel.formState.amountError != nil {
                focusedField = nil

                withAnimation(stepAnimation) {
                    currentStep = .amount
                }
            }

            shakeForm()
        }
        .onChange(of: viewModel.formState.savedTick) { _, tick in
            guard tick > 0 else { return }

            viewModel.consumeSavedTick()
            focusedField = nil
            localAmountError = nil

            withAnimation(.easeInOut(duration: 0.2)) {
                showSuccess = true
            }
        }
        .task(id: showSuccess) {
            guard showSuccess else { return }

            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            withAnimation(stepAnimation) {
                showSuccess = false
                currentStep = .amount
            }
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack(spacing: 12) {
            stepItem(
                number: "۱",
                title: "مبلغ هزینه",
                isActive: currentStep == .amount,
                isCompleted: currentStep == .description
            )

            Capsule()
                .fill(
                    currentStep == .description
                    ? AppTheme.primary
                    : AppTheme.outlineVariant
                )
                .frame(maxWidth: 48)
                .frame(height: 2)

            stepItem(
                number: "۲",
                title: "توضیحات",
                isActive: currentStep == .description,
                isCompleted: false
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func stepItem(
        number: String,
        title: String,
        isActive: Bool,
        isCompleted: Bool
    ) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isActive || isCompleted
                        ? AppTheme.primary
                        : AppTheme.surfaceContainerHigh
                    )
                    .frame(width: 30, height: 30)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.onPrimary)
                } else {
                    Text(number)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(
                            isActive
                            ? AppTheme.onPrimary
                            : AppTheme.onSurfaceVariant
                        )
                }
            }

            Text(title)
                .font(.subheadline.weight(isActive ? .bold : .medium))
                .foregroundStyle(
                    isActive || isCompleted
                    ? AppTheme.onSurface
                    : AppTheme.onSurfaceVariant
                )
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Step 1

    private var amountStepView: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    icon: "banknote.fill",
                    text: "چقدر هزینه کردی؟",
                    subtitle: "مبلغ هزینه را به تومان وارد کن"
                )

                VStack(spacing: 6) {
                    Text(
                        viewModel.formState.amount.isEmpty
                        ? "۰"
                        : viewModel.formState.amount.toMoneyOrEmpty()
                    )
                    .font(.system(size: 40, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(
                        viewModel.formState.amount.isEmpty
                        ? AppTheme.onSurfaceVariant.opacity(0.45)
                        : AppTheme.primary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                    .animation(
                        .easeOut(duration: 0.2),
                        value: viewModel.formState.amount
                    )

                    Text("تومان")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "keyboard")
                            .foregroundStyle(AppTheme.onSurfaceVariant)

                        TextField(
                            "مبلغ را وارد کنید",
                            text: Binding(
                                get: {
                                    viewModel.formState.amount.toMoneyOrEmpty()
                                },
                                set: {
                                    localAmountError = nil
                                    viewModel.onAmountChange($0)
                                }
                            )
                        )
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .amount)
                        .multilineTextAlignment(.trailing)
                        .font(.headline)
                        .foregroundStyle(AppTheme.onSurface)
                        .accessibilityLabel("مبلغ هزینه به تومان")

                        if !viewModel.formState.amount.isEmpty {
                            Button {
                                localAmountError = nil
                                viewModel.clearAmount()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(
                                        AppTheme.onSurfaceVariant
                                    )
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("پاک کردن مبلغ")
                        }
                    }
                    .padding(14)
                    .background(
                        AppTheme.surfaceContainerLow,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                amountError != nil
                                ? AppTheme.error
                                : focusedField == .amount
                                ? AppTheme.primary
                                : AppTheme.outlineVariant,
                                lineWidth: 1
                            )
                    }

                    if let error = amountError {
                        Label(
                            error,
                            systemImage: "exclamationmark.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.error)
                    }
                }



                VStack(alignment: .leading, spacing: 12) {
                    Label("افزودن سریع", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.onSurfaceVariant)

                    LazyVGrid(columns: chipColumns, spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { value in
                            BouncyChip(
                                label: "+ \(value.toShortToman().replacingOccurrences(of: " تومان", with: ""))",
                                isSelected: false
                            ) {
                                localAmountError = nil
                                viewModel.addQuickAmount(value)
                            }
                        }
                    }
                }
            }
            .modifier(ExpenseCardStyle())
            .modifier(
                ShakeEffect(animatableData: CGFloat(shakeTrigger))
            )

            Button(action: goToDescription) {
                HStack(spacing: 10) {
                    Text("مرحله بعدی")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundStyle(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    AppTheme.primary,
                    in: RoundedRectangle(cornerRadius: 20)
                )
            }
            .buttonStyle(ExpensePressStyle())
        }
    }

    // MARK: - Step 2

    private var descriptionStepView: some View {
        VStack(spacing: 18) {
            amountPreview

            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    icon: "text.alignright",
                    text: "بابت چی بود؟",
                    subtitle: "با یک توضیح کوتاه، هزینه‌ات را مشخص کن"
                )

                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(
                        text: Binding(
                            get: { viewModel.formState.description },
                            set: { viewModel.onDescriptionChange($0) }
                        )
                    )
                    .focused($focusedField, equals: .description)
                    .font(.body)
                    .foregroundStyle(AppTheme.onSurface)
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                    .padding(10)
                    .overlay(alignment: .topLeading) {
                        if viewModel.formState.description.isEmpty {
                            Text("مثلاً خرید نان، تاکسی یا ناهار…")
                                .font(.body)
                                .foregroundStyle(
                                    AppTheme.onSurfaceVariant.opacity(0.75)
                                )
                                .padding(.horizontal, 15)
                                .padding(.top, 18)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .background(
                        AppTheme.surfaceContainerLow,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                viewModel.formState.descriptionError != nil
                                ? AppTheme.error
                                : focusedField == .description
                                ? AppTheme.primary
                                : AppTheme.outlineVariant,
                                lineWidth: 1
                            )
                    }
                    .accessibilityLabel("توضیحات هزینه")

                    HStack(alignment: .top, spacing: 12) {
                        if let error = viewModel.formState.descriptionError {
                            Text(error)
                                .foregroundStyle(AppTheme.error)
                        } else {
                            Text("کوتاه و گویا بنویسید")
                                .foregroundStyle(
                                    AppTheme.onSurfaceVariant
                                )
                        }

                        Spacer(minLength: 4)

                        Text(
                            "\(viewModel.formState.description.count)/120"
                                .toPersianDigits()
                        )
                        .monospacedDigit()
                        .foregroundStyle(
                            viewModel.formState.description.count > 120
                            ? AppTheme.error
                            : AppTheme.onSurfaceVariant
                        )
                        .environment(\.layoutDirection, .leftToRight)
                    }
                    .font(.caption)
                }

                if !viewModel.topDescriptions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            "پیشنهادهای پرتکرار شما",
                            systemImage: "clock.arrow.circlepath"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.onSurfaceVariant)

                        LazyVGrid(columns: chipColumns, spacing: 8) {
                            ForEach(
                                viewModel.topDescriptions,
                                id: \.self
                            ) { text in
                                BouncyChip(
                                    label: text,
                                    isSelected:
                                        viewModel.formState.description == text
                                ) {
                                    viewModel.onDescriptionChange(text)
                                }
                            }
                        }
                    }
                }
            }
            .modifier(ExpenseCardStyle())
            .modifier(
                ShakeEffect(animatableData: CGFloat(shakeTrigger))
            )

            SaveButton(
                enabled: viewModel.formState.isValid,
                isSaving: viewModel.formState.isSaving
            ) {
                focusedField = nil
                viewModel.save()
            }

            Button(action: goToAmount) {
                Label("بازگشت به مبلغ", systemImage: "arrow.left")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(ExpensePressStyle())
        }
    }

    private var amountPreview: some View {
        HStack(spacing: 12) {
            Image(systemName: "banknote.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.onPrimaryContainer)
                .frame(width: 44, height: 44)
                .background(
                    AppTheme.primary.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("مبلغ این هزینه")
                    .font(.caption)
                    .foregroundStyle(AppTheme.onPrimaryContainer)

                Text(
                    "\(viewModel.formState.amountValue.toMoney()) تومان"
                )
                .font(.headline)
                .foregroundStyle(AppTheme.onPrimaryContainer)
            }

            Spacer(minLength: 8)

            Button(action: goToAmount) {
                Image(systemName: "square.and.pencil")
                    .font(.headline)
                    .foregroundStyle(AppTheme.onPrimaryContainer)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(ExpensePressStyle())
            .accessibilityLabel("ویرایش مبلغ")
        }
        .padding(16)
        .background(
            AppTheme.primaryContainer,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Actions

    private func goToDescription() {
        guard !viewModel.formState.isSaving else { return }

        guard viewModel.formState.amountValue > 0 else {
            localAmountError = "مبلغی بیشتر از صفر وارد کنید"
            focusedField = .amount
            shakeForm()
            return
        }

        guard viewModel.formState.amountError == nil else {
            focusedField = .amount
            shakeForm()
            return
        }

        localAmountError = nil
        focusedField = nil

        withAnimation(stepAnimation) {
            currentStep = .description
        }
    }

    private func goToAmount() {
        guard !viewModel.formState.isSaving else { return }

        focusedField = nil

        withAnimation(stepAnimation) {
            currentStep = .amount
        }
    }

    private func shakeForm() {
        guard !reduceMotion else { return }

        withAnimation(.linear(duration: 0.4)) {
            shakeTrigger += 1
        }
    }
}

// MARK: - Header


private struct GradientHeader: View {
    let total: Int64
    let topInset: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 7) {
                Image(systemName: "creditcard.fill")

                Text("ثبت هزینه جدید")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.emeraldLight)

                VStack(alignment: .leading, spacing: 5) {
                    Text("جمع کل هزینه‌ها")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))

                    HStack(
                        alignment: .firstTextBaseline,
                        spacing: 5
                    ) {
                        Text(total.toMoney())
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(
                                .easeOut(duration: 0.25),
                                value: total
                            )

                        Text("تومان")
                    }
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.10))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        .white.opacity(0.12),
                        lineWidth: 1
                    )
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, topInset + 20)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            AppTheme.brandGradient
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(AppTheme.mint.opacity(0.12))
                        .frame(width: 180, height: 180)
                        .blur(radius: 24)
                        .offset(x: 50, y: -70)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: 32,
                        bottomTrailingRadius: 32
                    )
                )
        }
    }
}

// MARK: - Section title

private struct SectionTitle: View {
    let icon: String
    let text: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.onPrimaryContainer)
                .frame(width: 44, height: 44)
                .background(
                    AppTheme.primaryContainer,
                    in: RoundedRectangle(cornerRadius: 14)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(text)
                    .font(.headline)
                    .foregroundStyle(AppTheme.onSurface)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Chips

private struct BouncyChip: View {
    let label: String
    let isSelected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundStyle(
                    isSelected
                    ? AppTheme.onPrimary
                    : AppTheme.onSurfaceVariant
                )
                .background(
                    isSelected
                    ? AppTheme.primary
                    : AppTheme.surfaceContainerLow,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected
                            ? Color.clear
                            : AppTheme.outlineVariant,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(ExpensePressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Save button

private struct SaveButton: View {
    let enabled: Bool
    let isSaving: Bool
    let onClick: () -> Void

    private var isHighlighted: Bool {
        enabled || isSaving
    }

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)

                    Text("در حال ذخیره…")
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("ذخیره هزینه")
                }
            }
            .font(.headline)
            .foregroundStyle(
                isHighlighted
                ? Color.white
                : AppTheme.onSurfaceVariant
            )
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                if isHighlighted {
                    AppTheme.brandGradient
                } else {
                    AppTheme.surfaceContainerHigh
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .disabled(!enabled || isSaving)
        .buttonStyle(ExpensePressStyle())
    }
}

// MARK: - Success

private struct SuccessOverlay: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.onPrimaryContainer)
                    .frame(width: 80, height: 80)
                    .background(
                        AppTheme.primaryContainer,
                        in: Circle()
                    )
                    .padding(.bottom, 4)

                Text("با موفقیت ثبت شد")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.onSurface)

                Text("هزینه‌ات به تاریخچه اضافه شد")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .frame(maxWidth: 320)
            .background(
                AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 30)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            }
            .shadow(
                color: .black.opacity(0.15),
                radius: 24,
                y: 10
            )
            .scaleEffect(appeared || reduceMotion ? 1 : 0.88)
            .opacity(appeared ? 1 : 0)
            .padding(24)
            .accessibilityElement(children: .combine)
        }
        .onAppear {
            withAnimation(
                reduceMotion
                ? .easeOut(duration: 0.15)
                : .spring(response: 0.4, dampingFraction: 0.75)
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Card style

private struct ExpenseCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 26)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        AppTheme.outlineVariant.opacity(0.7),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(0.035),
                radius: 14,
                y: 6
            )
    }
}

// MARK: - Button style

private struct ExpensePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotion ? 0.97 : 1
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(
                .easeOut(duration: 0.15),
                value: configuration.isPressed
            )
    }
}


// MARK: - Rounded Corner Helper
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let amplitude: CGFloat = 10
        let shakes: CGFloat = 3

        let translation = amplitude * sin(
            animatableData * .pi * 2 * shakes
        )

        return ProjectionTransform(
            CGAffineTransform(
                translationX: translation,
                y: 0
            )
        )
    }
}

//
//  CommitmentAgreementContentView.swift
//  LockedIn
//
//  Final commitment screen — contract design.
//  Feels like a real document: clause numbers, signature line,
//  handwritten font, and a seal glow when the contract becomes active.
//

import SwiftUI

struct CommitmentAgreementContentView: View {
    @ObservedObject var viewModel: CommitmentAgreementViewModel

    private let accentColor = Color(hex: "#22D3EE")

    @State private var headerVisible = false
    @State private var termsVisible  = false
    @State private var formVisible   = false

    private var contractActive: Bool {
        !viewModel.fullName.trimmingCharacters(in: .whitespaces).isEmpty
            && viewModel.hasAcceptedTerms
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer().frame(height: 160)

                let horizontalPadding = Theme.Spacing.xl
                let contentWidth = min(
                    max(0, proxy.size.width - (horizontalPadding * 2)),
                    460
                )

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xl) {
                        documentHeader
                            .opacity(headerVisible ? 1 : 0)
                            .offset(y: headerVisible ? 0 : 10)

                        termsSection
                            .opacity(termsVisible ? 1 : 0)
                            .offset(y: termsVisible ? 0 : 10)

                        signatureForm
                            .opacity(formVisible ? 1 : 0)
                            .offset(y: formVisible ? 0 : 10)

                        Spacer().frame(height: 80)
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.bottom, Theme.Spacing.xl)
                    .frame(width: proxy.size.width)
                }
                .frame(width: proxy.size.width)

                Spacer().frame(height: 140)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(backgroundLayer)
            .clipped()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                headerVisible = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.15)) {
                termsVisible = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.28)) {
                formVisible = true
            }
        }
    }
}

// MARK: - Background

private extension CommitmentAgreementContentView {
    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Seal glow — activates when contract is complete
            Circle()
                .fill(accentColor.opacity(contractActive ? 0.09 : 0))
                .frame(width: 460, height: 460)
                .blur(radius: 90)
                .scaleEffect(contractActive ? 1 : 0.6)
                .animation(.spring(response: 0.7, dampingFraction: 0.75), value: contractActive)
                .allowsHitTesting(false)
                .clipped()

            // Ambient top glow
            Circle()
                .fill(accentColor.opacity(0.05))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -80, y: -200)
                .allowsHitTesting(false)
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .clipped()
    }
}

// MARK: - Document Header

private extension CommitmentAgreementContentView {
    var documentHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Top rule + agreement number
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)

                Text("AGREEMENT №001")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Color.white.opacity(0.3))
                    .fixedSize()
            }

            Text("Personal Commitment\nAgreement")
                .font(.custom("Inter", size: 28).weight(.heavy))
                .tracking(-0.5)
                .lineSpacing(2)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)

            Text("By signing this document, you are entering into a binding agreement with your future self. The terms below are designed to enforce discipline.")
                .font(.custom("Inter", size: 14))
                .foregroundColor(Color.white.opacity(0.45))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Terms

private extension CommitmentAgreementContentView {
    var termsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            GlassCard {
                VStack(spacing: 0) {
                    clauseRow(number: "§1", title: "Non-Negotiables",  subtitle: "Locked strictly for the entire duration",  isLast: false)
                    clauseRow(number: "§2", title: "Violations",        subtitle: "Recorded permanently on your record",      isLast: false)
                    clauseRow(number: "§3", title: "Emergency Unlock",  subtitle: "Requires written explanation",             isLast: true)
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }

            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("Read full details")
                        .font(.custom("Inter", size: 13).weight(.medium))
                        .foregroundColor(accentColor)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundColor(accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func clauseRow(number: String, title: String, subtitle: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.md) {
                Text(number)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor.opacity(0.7))
                    .frame(width: 28, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.custom("Inter", size: 15).weight(.semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.custom("Inter", size: 12))
                        .foregroundColor(Color.white.opacity(0.4))
                }

                Spacer()
            }
            .padding(.vertical, Theme.Spacing.md)

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Signature Form

private extension CommitmentAgreementContentView {
    var signatureForm: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Date row
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                formFieldLabel("Date")

                HStack {
                    Text(currentDateString())
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.4))
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .frame(height: 44)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }

            // Signature field
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: 4) {
                    formFieldLabel("Signature")
                    Text("*")
                        .font(.custom("Inter", size: 12).weight(.bold))
                        .foregroundColor(accentColor)
                }

                // Dashed signature line with handwritten text on top
                ZStack(alignment: .leading) {
                    // The dashed line
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 56)
                        .overlay(
                            VStack {
                                Spacer()
                                signatureLine
                            }
                        )

                    // Handwritten name or placeholder
                    if viewModel.fullName.isEmpty {
                        Text("Your name")
                            .font(.custom("SnellRoundhand", size: 26))
                            .foregroundColor(Color.white.opacity(0.18))
                            .padding(.horizontal, 4)
                            .padding(.bottom, 10)
                            .allowsHitTesting(false)
                    }

                    // Actual text field — invisible, sits over the line
                    HStack {
                        TextField("", text: $viewModel.fullName)
                            .font(.custom("SnellRoundhand", size: 28))
                            .foregroundColor(accentColor)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 4)

                        if !viewModel.fullName.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                                .padding(.bottom, 8)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xs)
                .overlay(
                    // Highlight border when validation fails
                    viewModel.fullName.isEmpty && viewModel.showValidationError
                        ? AnyView(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                                .stroke(accentColor.opacity(0.7), lineWidth: 1)
                        )
                        : AnyView(EmptyView())
                )

                Text("By typing your name, you accept the terms above.")
                    .font(.custom("Inter", size: 11))
                    .foregroundColor(Color.white.opacity(0.28))
                    .padding(.leading, 4)
            }

            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    viewModel.toggleTermsAccepted()
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                viewModel.hasAcceptedTerms ? accentColor : Color.white.opacity(0.22),
                                lineWidth: 1.5
                            )
                            .frame(width: 22, height: 22)

                        if viewModel.hasAcceptedTerms {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(accentColor.opacity(0.18))
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                    }

                    Text("I agree on the terms and services")
                        .font(.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(viewModel.hasAcceptedTerms ? Theme.Colors.textPrimary : Color.white.opacity(0.38))

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Validation error
            if viewModel.showValidationError {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                    Text("Your signature is required to proceed")
                        .font(.custom("Inter", size: 12).weight(.medium))
                        .foregroundColor(accentColor)
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // Dashed signature underline
    var signatureLine: some View {
        GeometryReader { geo in
            Path { path in
                let dashWidth: CGFloat = 8
                let gapWidth:  CGFloat = 5
                var x: CGFloat = 0
                while x < geo.size.width {
                    path.move(to:    CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: min(x + dashWidth, geo.size.width), y: 0))
                    x += dashWidth + gapWidth
                }
            }
            .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .frame(height: 1)
    }

    @ViewBuilder
    func formFieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.custom("Inter", size: 10).weight(.semibold))
            .tracking(1.5)
            .foregroundColor(Color.white.opacity(0.4))
    }

    func currentDateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: Date())
    }
}

// MARK: - Preview

struct CommitmentAgreementContentView_Previews: PreviewProvider {
    static var previews: some View {
        CommitmentAgreementContentView(viewModel: CommitmentAgreementViewModel())
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}

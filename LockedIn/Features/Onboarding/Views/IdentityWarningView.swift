//
//  IdentityWarningView.swift
//  LockedIn
//
//  Identity & Warning onboarding screen (Screen 1 of 7)
//  Design sourced from Google Stitch MCP
//
//  Layout structure from Stitch HTML:
//    - Background: statue image + radial gradient overlay + refraction accents
//    - Header: close/help icons + 7-segment progress bar + step label
//    - Content: liquid glass card with headline, body, separator, secondary text
//    - Footer: full-width CTA button + subtitle
//

import SwiftUI

struct IdentityWarningView: View {
    @StateObject private var viewModel: IdentityWarningViewModel
    
    init(onContinue: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: IdentityWarningViewModel(onContinue: onContinue))
    }
    
    var body: some View {
        ZStack {
            // Background layer
            backgroundLayer
            
            // Glass refraction accents
            refractionAccents
            
            // Content
            VStack(spacing: 0) {
                // Header: icons + progress + step label
                headerSection
                
                Spacer()
                
                // Main content: liquid glass card
                contentCard
                
                Spacer()
                
                // Footer: CTA button + subtitle
                footerSection
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Background Layer
private extension IdentityWarningView {
    var backgroundLayer: some View {
        ZStack {
            // Base background color
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            // Statue image (The Regulator)
            // Stitch: opacity-40 grayscale contrast-125 scale-110
            statueImage
            
            // Radial gradient overlay (statue-overlay)
            // Stitch: radial-gradient(circle at center, transparent 0%, rgba(10, 5, 5, 1) 90%)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color(hex: "#0a0505").opacity(0.6),
                    Color(hex: "#0a0505")
                ]),
                center: .center,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.55
            )
            .ignoresSafeArea()
        }
    }
    
    var statueImage: some View {
        // Statue image from Stitch design (The Regulator)
        // Stitch: opacity-40 grayscale contrast-125 scale-110
        GeometryReader { geo in
            ZStack {
                // Try to load the actual image asset first
                if let _ = UIImage(named: "regulator_statue") {
                    Image("regulator_statue")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 1.1, height: geo.size.height * 1.1)
                        .clipped()
                } else {
                    // Fallback to silhouette if image not found
                    RegulatorSilhouette()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(0.40)
            .saturation(0)       // grayscale
            .contrast(1.25)      // contrast-125
            .scaleEffect(1.10)   // scale-110
        }
        .ignoresSafeArea()
    }
    
    var refractionAccents: some View {
        ZStack {
            // Top-left accent
            // Stitch: absolute top-1/4 -left-20 w-64 h-64 bg-primary/5 rounded-full blur-[100px]
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: -100, y: -UIScreen.main.bounds.height * 0.25)
            
            // Bottom-right accent
            // Stitch: absolute bottom-1/4 -right-20 w-64 h-64 bg-primary/5 rounded-full blur-[100px]
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: 100, y: UIScreen.main.bounds.height * 0.25)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Header Section
private extension IdentityWarningView {
    var headerSection: some View {
        VStack(spacing: 0) {
            // Top icons row (close + help)
            // Stitch: px-6 pt-12 pb-6
            HStack {
                // Close icon
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.textSubtle) // text-white/50
                
                Spacer()
                
                // Help icon
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.textSubtle) // text-white/50
            }
            .padding(.horizontal, Theme.Spacing.xl) // px-6 = 24px
            .padding(.top, 60) // pt-12 (safe area + padding)
            .padding(.bottom, Theme.Spacing.xl) // mb-6
            
            // 7-Segment Progress Bar
            ProgressIndicator(
                totalSteps: viewModel.totalSteps,
                currentStep: viewModel.currentStep
            )
            .padding(.horizontal, Theme.Spacing.xl)
            
            // Step label
            // Stitch: mt-3 text-[10px] uppercase tracking-[0.2em] text-white/40 font-bold
            Text(viewModel.stepLabel.uppercased())
                .font(Theme.Typography.caption())
                .tracking(Theme.Typography.letterSpacingWidest * 10) // tracking-[0.2em]
                .foregroundColor(Theme.Colors.textTertiary) // text-white/40
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm) // mt-3 = 12px
        }
    }
}

// MARK: - Content Card
private extension IdentityWarningView {
    var contentCard: some View {
        // Stitch: liquid-glass rounded-xl p-8 space-y-6
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) { // space-y-6 = 24px
                // Top section: headline + body
                VStack(alignment: .leading, spacing: Theme.Spacing.md) { // space-y-4 = 16px
                    headlineText
                    bodyText
                }
                
                // Separator + secondary text
                // Stitch: pt-4 border-t border-white/5
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    secondaryText
                        .padding(.top, Theme.Spacing.md) // pt-4 = 16px
                }
            }
            .padding(Theme.Spacing.xxl) // p-8 = 32px
        }
        .padding(.horizontal, Theme.Spacing.xl) // px-6 = 24px
    }
    
    // Stitch: text-3xl font-bold leading-tight tracking-tight text-white
    // LEFT aligned (not center)
    var headlineText: some View {
        (
            Text(viewModel.headline)
                .foregroundColor(Theme.Colors.textPrimary)
            +
            Text(viewModel.highlightedWord)
                .foregroundColor(Theme.Colors.authority)
            +
            Text(viewModel.headlineSuffix)
                .foregroundColor(Theme.Colors.textPrimary)
        )
        .font(Theme.Typography.displayLarge().weight(.bold))
        .tracking(-0.5) // tracking-tight
        .lineSpacing(2) // leading-tight
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("\(viewModel.headline)\(viewModel.highlightedWord)\(viewModel.headlineSuffix)")
    }
    
    // Stitch: text-white/80 text-base leading-relaxed font-medium
    // LEFT aligned
    var bodyText: some View {
        Text(viewModel.bodyText)
            .font(Theme.Typography.bodyLarge())
            .foregroundColor(Theme.Colors.textSecondary) // text-white/80
            .lineSpacing(6) // leading-relaxed
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // Stitch: text-sm text-white/40 leading-snug italic
    // LEFT aligned
    var secondaryText: some View {
        Text(viewModel.secondaryText)
            .font(Theme.Typography.bodyMedium())
            .italic()
            .foregroundColor(Theme.Colors.textTertiary) // text-white/40
            .lineSpacing(2) // leading-snug
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Footer Section
private extension IdentityWarningView {
    var footerSection: some View {
        // Stitch: p-6 pb-10
        VStack(spacing: Theme.Spacing.md) { // mt-4 between button and subtitle
            // CTA Button
            PrimaryButton(
                title: viewModel.ctaTitle,
                showArrow: true,
                action: viewModel.didTapContinue
            )
            
            // Subtitle below button
            // Stitch: text-[11px] text-white/30 uppercase tracking-widest font-semibold text-center
            Text(viewModel.ctaSubtitle.uppercased())
                .font(Theme.Typography.captionSmall())
                .tracking(Theme.Typography.letterSpacingWidest * 11) // tracking-widest
                .foregroundColor(Theme.Colors.textMuted) // text-white/30
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.xl) // p-6 = 24px
        .padding(.bottom, 40) // pb-10 = 40px
    }
}

// MARK: - Regulator Silhouette (Fallback for statue image)
private struct RegulatorSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            
            ZStack {
                // Abstract stoic figure
                Path { path in
                    // Head
                    path.addEllipse(in: CGRect(
                        x: centerX - 45,
                        y: height * 0.12,
                        width: 90,
                        height: 100
                    ))
                    
                    // Neck
                    path.addRect(CGRect(
                        x: centerX - 15,
                        y: height * 0.22,
                        width: 30,
                        height: 30
                    ))
                    
                    // Shoulders and torso
                    path.move(to: CGPoint(x: centerX - 100, y: height * 0.28))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + 100, y: height * 0.28),
                        control: CGPoint(x: centerX, y: height * 0.24)
                    )
                    path.addLine(to: CGPoint(x: centerX + 75, y: height * 0.55))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - 75, y: height * 0.55),
                        control: CGPoint(x: centerX, y: height * 0.58)
                    )
                    path.closeSubpath()
                    
                    // Lower body / pedestal
                    path.move(to: CGPoint(x: centerX - 60, y: height * 0.55))
                    path.addLine(to: CGPoint(x: centerX + 60, y: height * 0.55))
                    path.addLine(to: CGPoint(x: centerX + 80, y: height * 0.85))
                    path.addLine(to: CGPoint(x: centerX - 80, y: height * 0.85))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

// MARK: - Preview
struct IdentityWarningView_Previews: PreviewProvider {
    static var previews: some View {
        IdentityWarningView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}

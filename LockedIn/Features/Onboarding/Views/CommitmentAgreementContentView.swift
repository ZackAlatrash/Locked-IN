//
//  CommitmentAgreementContentView.swift
//  LockedIn
//
//  Content-only view for Screen 8 (Final Commitment Agreement)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Contract-style design for personal commitment
//

import SwiftUI

struct CommitmentAgreementContentView: View {
    // MARK: - Bindings (explicit dependency injection)
    @Binding var hasAcceptedTerms: Bool
    @Binding var fullName: String
    @Binding var showValidationError: Bool
    
    var body: some View {
        ZStack {
            // Full-screen background - pure black for contract vibe
            Color.black.ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Space for header overlay
                Spacer().frame(height: 160)
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header Section
                        headerSection
                        
                        // Terms Grid
                        termsSection
                        
                        // Read full details link
                        readMoreLink
                        
                        // Signature Form
                        signatureForm
                        
                        // Extra scroll space
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
                }
                
                // Space for CTA button
                Spacer().frame(height: 140)
            }
        }
    }
}

// MARK: - Header Section
private extension CommitmentAgreementContentView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Personal Commitment Agreement")
                .font(.system(size: 28, weight: .heavy))
                .tracking(-0.5)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Text("By signing this document, you are entering into a binding agreement with your future self. The terms below are designed to enforce discipline.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textMuted)
                .lineSpacing(3)
        }
    }
}

// MARK: - Terms Section
private extension CommitmentAgreementContentView {
    var termsSection: some View {
        VStack(spacing: 0) {
            // Divider top
            Divider()
                .background(Theme.Colors.border)
            
            // Term 1: Non-Negotiables
            termRow(
                title: "Non-Negotiables",
                subtitle: "Locked strictly for the entire duration",
                icon: "lock.fill"
            )
            
            // Divider
            Divider()
                .background(Theme.Colors.border)
            
            // Term 2: Violations
            termRow(
                title: "Violations",
                subtitle: "Recorded permanently on your record",
                icon: "doc.text.fill"
            )
            
            // Divider
            Divider()
                .background(Theme.Colors.border)
            
            // Term 3: Emergency Unlock
            termRow(
                title: "Emergency Unlock",
                subtitle: "Requires written explanation",
                icon: "exclamationmark.triangle.fill"
            )
            
            // Divider bottom
            Divider()
                .background(Theme.Colors.border)
        }
    }
    
    func termRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.authority)
        }
        .padding(.vertical, Theme.Spacing.lg)
    }
    
    var readMoreLink: some View {
        Button(action: {
            // Show full terms
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Text("Read full details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.authority)
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.authority)
            }
        }
    }
}

// MARK: - Signature Form
private extension CommitmentAgreementContentView {
    var signatureForm: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Date Field (Read Only)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Date")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                
                HStack {
                    Text(currentDateString())
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.textMuted)
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.surfaceDark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            
            // Full Name Input
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Full Name (Signature)")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                    
                    Text("*")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.authority)
                }
                
                HStack {
                    TextField("", text: $fullName, prompt: Text("Type your name").foregroundColor(Theme.Colors.textMuted.opacity(0.5)))
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    
                    if !fullName.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.Colors.authority)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.surfaceDark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(fullName.isEmpty && showValidationError ? Theme.Colors.authority : Theme.Colors.border, lineWidth: fullName.isEmpty && showValidationError ? 2 : 1)
                )
                
                Text("By typing your name, you accept the terms above.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.leading, Theme.Spacing.xs)
            }
            
            // Terms & Conditions Checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    hasAcceptedTerms.toggle()
                    showValidationError = false
                }
            }) {
                HStack(spacing: Theme.Spacing.md) {
                    // Checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(hasAcceptedTerms ? Theme.Colors.authority : Theme.Colors.border, lineWidth: 2)
                            .frame(width: 22, height: 22)
                        
                        if hasAcceptedTerms {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.authority)
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("I accept the terms and conditions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(hasAcceptedTerms ? .white : Theme.Colors.textMuted)
                    
                    Spacer()
                }
            }
            .padding(.top, Theme.Spacing.sm)
            
            // Validation error message
            if showValidationError {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.authority)
                    
                    Text("You must accept the terms to continue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.authority)
                    
                    Spacer()
                }
                .padding(.top, Theme.Spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview
struct CommitmentAgreementContentView_Previews: PreviewProvider {
    static var previews: some View {
        CommitmentAgreementContentView(
            hasAcceptedTerms: .constant(false),
            fullName: .constant(""),
            showValidationError: .constant(false)
        )
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

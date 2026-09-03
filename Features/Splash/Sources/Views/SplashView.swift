import SwiftUI
import CoreDesignSystem
import CoreNavigation
import FactoryKit

@MainActor
public struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0

    public init() {
        _viewModel = StateObject(wrappedValue: SplashViewModel())
    }

    public var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 16, x: 0, y: 8)

                    Image(systemName: "bag.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("MyTuistProject")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.primary)

                    Text("Clean Architecture & Modular Engine")
                        .font(.footnote)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .opacity(logoOpacity)

                Spacer()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                    .scaleEffect(1.2)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            viewModel.onAppear()
        }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
#endif

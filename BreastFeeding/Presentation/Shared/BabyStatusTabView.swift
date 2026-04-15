import SwiftUI

struct BabyStatusTabView: View {
    @StateObject var viewModel: BabyStatusDashboardViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                BabyStatusDashboardView(viewModel: viewModel)
                Spacer()
            }
            .padding()
            .navigationTitle("Стан дитини")
            .background(AppTheme.warmBackground.ignoresSafeArea())
        }
    }
}

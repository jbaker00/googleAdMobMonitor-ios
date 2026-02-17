import SwiftUI

struct PayoutDetailsView: View {
  @ObservedObject var viewModel: StatsViewModel
  let reportCurrency: String
  
  var body: some View {
    List {
      if viewModel.payoutHistory.isEmpty {
        Text("Loading...")
          .task {
            await viewModel.loadPayoutDetails()
          }
      } else {
        ForEach(viewModel.payoutHistory) { entry in
          HStack {
            VStack(alignment: .leading) {
              Text(entry.monthLabel).font(.caption).foregroundStyle(.secondary)
              Text(entry.appName).font(.subheadline).lineLimit(1)
            }
            Spacer()
            Text((viewModel.payoutCurrency.isEmpty ? reportCurrency : viewModel.payoutCurrency) + " " + entry.estimatedEarningsFormatted)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.green)
          }
        }
      }
    }
    .navigationTitle("Payout details")
  }
}

#Preview {
  PayoutDetailsView(viewModel: StatsViewModel(), reportCurrency: "USD")
}

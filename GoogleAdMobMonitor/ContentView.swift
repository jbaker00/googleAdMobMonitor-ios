import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var viewModel: StatsViewModel

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isSignedIn {
          statsView
        } else {
          signInView
        }
      }
      .navigationTitle("AdMob Stats")
    }
    .task {
      await viewModel.restorePreviousSignInIfPossible()
    }
  }

  private var signInView: some View {
    VStack(spacing: 16) {
      Text("Sign in to view your AdMob stats.")
        .multilineTextAlignment(.center)

      Button("Sign in with Google") {
        Task { await viewModel.signIn() }
      }
      .buttonStyle(.borderedProminent)

      if let error = viewModel.errorMessage {
        Text(error).foregroundStyle(.red).font(.caption)
      }
    }
    .padding()
  }

  private var statsView: some View {
    VStack(spacing: 0) {
      if viewModel.isLoading {
        ProgressView("Loading reports…")
          .padding()
      } else if let multiReport = viewModel.multiPeriodReport {
        List {
          // Today Section
          timePeriodSection(report: multiReport.today, currency: multiReport.currencyCode)
          
          // Yesterday Section
          timePeriodSection(report: multiReport.yesterday, currency: multiReport.currencyCode)
          
          // Last 7 Days Section
          timePeriodSection(report: multiReport.last7Days, currency: multiReport.currencyCode)
          
          // Last 30 Days Section
          timePeriodSection(report: multiReport.last30Days, currency: multiReport.currencyCode)
        }
        .listStyle(.insetGrouped)
      } else {
        Text("No report loaded yet.")
          .padding()
      }
      
      // Bottom toolbar
      HStack(spacing: 16) {
        Button {
          Task { await viewModel.refresh() }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isLoading)
        
        Spacer()
        
        Button {
          viewModel.signOut()
        } label: {
          Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
        }
        .buttonStyle(.bordered)
      }
      .padding()
      .background(Color(.systemGroupedBackground))
      
      if let error = viewModel.errorMessage {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
          .padding(.horizontal)
      }
    }
  }
  
  @ViewBuilder
  private func timePeriodSection(report: TimePeriodReport, currency: String) -> some View {
    Section {
      // Total earnings for this period
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Total Earnings")
            .font(.headline)
          Spacer()
          Text(currency + " " + report.totalStats.estimatedEarningsFormatted)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.green)
        }
        
        // Additional metrics
        HStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Impressions")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(report.totalStats.impressionsFormatted)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text("Clicks")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(report.totalStats.clicksFormatted)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text("Requests")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(report.totalStats.adRequestsFormatted)
              .font(.subheadline)
              .fontWeight(.medium)
          }
        }
        .font(.system(.caption, design: .rounded))
      }
      .padding(.vertical, 8)
      
      // Apps breakdown
      if !report.appBreakdown.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text("By App")
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
          
          ForEach(report.appBreakdown) { app in
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .lineLimit(1)
                
                HStack(spacing: 16) {
                  Label(app.impressionsFormatted, systemImage: "eye")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  Label(app.clicksFormatted, systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              
              Spacer()
              
              Text(currency + " " + app.estimatedEarningsFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
          }
        }
      }
      
      // Countries breakdown
      if !report.countryBreakdown.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text("By Country")
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
          
          ForEach(report.countryBreakdown) { country in
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(country.displayName)
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .lineLimit(1)
                
                HStack(spacing: 16) {
                  Label(country.impressionsFormatted, systemImage: "eye")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  Label(country.clicksFormatted, systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              
              Spacer()
              
              Text(currency + " " + country.estimatedEarningsFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
          }
        }
      }
    } header: {
      HStack {
        Text(report.periodLabel)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
        Text(report.dateRange)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

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
  ContentView().environmentObject(StatsViewModel())
}

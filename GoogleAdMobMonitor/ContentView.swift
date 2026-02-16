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
        ProgressView("Loading report…")
          .padding()
      } else if let report = viewModel.report {
        // Date range picker
        Picker("Time Period", selection: $viewModel.selectedDateRange) {
          ForEach(DateRangeOption.allCases) { option in
            Text(option.rawValue).tag(option)
          }
        }
        .pickerStyle(.segmented)
        .padding()
        .onChange(of: viewModel.selectedDateRange) { _, _ in
          Task { await viewModel.refresh() }
        }
        
        // Summary section
        VStack(alignment: .leading, spacing: 8) {
          Text("Total (\(report.totalStats.dateRange))")
            .font(.headline)
            .padding(.horizontal)
          
          Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
              Text("Currency:").foregroundStyle(.secondary)
              Text(report.currencyCode).fontWeight(.medium)
            }
            GridRow {
              Text("Earnings:").foregroundStyle(.secondary)
              Text(report.currencyCode + " " + report.totalStats.estimatedEarningsFormatted)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            }
            GridRow {
              Text("Impressions:").foregroundStyle(.secondary)
              Text(report.totalStats.impressionsFormatted).fontWeight(.medium)
            }
            GridRow {
              Text("Clicks:").foregroundStyle(.secondary)
              Text(report.totalStats.clicksFormatted).fontWeight(.medium)
            }
            GridRow {
              Text("Requests:").foregroundStyle(.secondary)
              Text(report.totalStats.adRequestsFormatted).fontWeight(.medium)
            }
          }
          .font(.system(.body, design: .rounded))
          .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
        
        // App breakdown table
        List {
          Section {
            ForEach(report.appBreakdown) { app in
              VStack(alignment: .leading, spacing: 6) {
                Text(app.displayName)
                  .font(.headline)
                  .lineLimit(1)
                
                HStack {
                  VStack(alignment: .leading, spacing: 2) {
                    Text("Earnings")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Text(report.currencyCode + " " + app.estimatedEarningsFormatted)
                      .font(.subheadline)
                      .fontWeight(.semibold)
                      .foregroundStyle(.green)
                  }
                  
                  Spacer()
                  
                  VStack(alignment: .trailing, spacing: 2) {
                    Text("Impressions")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Text(app.impressionsFormatted)
                      .font(.subheadline)
                      .fontWeight(.medium)
                  }
                  
                  Spacer()
                  
                  VStack(alignment: .trailing, spacing: 2) {
                    Text("Clicks")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Text(app.clicksFormatted)
                      .font(.subheadline)
                      .fontWeight(.medium)
                  }
                }
                .font(.system(.caption, design: .rounded))
              }
              .padding(.vertical, 4)
            }
          } header: {
            Text("Apps (\(report.appBreakdown.count))")
          }
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
}

#Preview {
  ContentView().environmentObject(StatsViewModel())
}

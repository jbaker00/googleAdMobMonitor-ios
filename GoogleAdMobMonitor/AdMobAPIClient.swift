import Foundation

enum DateRangeOption: String, CaseIterable, Identifiable {
  case monthToDate = "Month to Date"
  case last30Days = "Last 30 Days"
  case last60Days = "Last 60 Days"
  case last1Year = "Last 1 Year"
  case allTime = "All Time"
  
  var id: String { rawValue }
  
  func dateRange() -> (start: Date, end: Date) {
    let cal = Calendar.current
    let now = Date()
    let end = now
    
    switch self {
    case .monthToDate:
      let start = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: cal.component(.month, from: now), day: 1)) ?? now
      return (start, end)
    case .last30Days:
      let start = cal.date(byAdding: .day, value: -30, to: now) ?? now
      return (start, end)
    case .last60Days:
      let start = cal.date(byAdding: .day, value: -60, to: now) ?? now
      return (start, end)
    case .last1Year:
      let start = cal.date(byAdding: .year, value: -1, to: now) ?? now
      return (start, end)
    case .allTime:
      // AdMob launched in 2006, use a safe date far back
      let start = cal.date(from: DateComponents(year: 2010, month: 1, day: 1)) ?? now
      return (start, end)
    }
  }
}

struct PublisherAccount: Decodable {
  let name: String // e.g. "accounts/pub-9876543210987654"
  let publisherId: String?
}

struct ListPublisherAccountsResponse: Decodable {
  let account: [PublisherAccount]?
}

struct GenerateNetworkReportRequest: Encodable {
  let reportSpec: NetworkReportSpec
}

struct NetworkReportSpec: Encodable {
  let dateRange: DateRange
  let dimensions: [String]?
  let metrics: [String]
  let localizationSettings: LocalizationSettings
}

struct DateRange: Encodable {
  let startDate: ReportDate
  let endDate: ReportDate
}

struct ReportDate: Encodable {
  let year: Int
  let month: Int
  let day: Int
}

struct LocalizationSettings: Encodable {
  let currencyCode: String?
  let languageCode: String?
}

struct GenerateNetworkReportResponse: Decodable {
  let header: ReportHeader?
  let row: ReportRow?
  let footer: ReportFooter?
}

struct ReportHeader: Decodable {
  let dateRange: HeaderDateRange?
  let localizationSettings: HeaderLocalizationSettings?
}

struct HeaderDateRange: Decodable {
  let startDate: ReportDateDecoded?
  let endDate: ReportDateDecoded?
}

struct ReportDateDecoded: Decodable {
  let year: Int
  let month: Int
  let day: Int
}

struct HeaderLocalizationSettings: Decodable {
  let currencyCode: String?
  let languageCode: String?
}

struct ReportRow: Decodable {
  let dimensionValues: [String: DimensionValue]?
  let metricValues: [String: MetricValue]?
}

struct DimensionValue: Decodable {
  let value: String?
  let displayLabel: String?
}

struct MetricValue: Decodable {
  let integerValue: String?
  let doubleValue: Double?
  let microsValue: String?
}

struct ReportFooter: Decodable {
  let matchingRowCount: String?
}

struct MTDReportSummary {
  let dateRange: String
  let currencyCode: String
  let estimatedEarningsMicros: Int64
  let impressions: Int64
  let clicks: Int64
  let adRequests: Int64

  var estimatedEarningsFormatted: String {
    let units = Double(estimatedEarningsMicros) / 1_000_000.0
    return String(format: "%.2f", units)
  }

  var impressionsFormatted: String { impressions.formatted() }
  var clicksFormatted: String { clicks.formatted() }
  var adRequestsFormatted: String { adRequests.formatted() }
}

struct AppStats: Identifiable {
  let id: String // APP dimension value
  let displayName: String
  let estimatedEarningsMicros: Int64
  let impressions: Int64
  let clicks: Int64
  let adRequests: Int64
  
  var estimatedEarningsFormatted: String {
    let units = Double(estimatedEarningsMicros) / 1_000_000.0
    return String(format: "%.2f", units)
  }
  
  var impressionsFormatted: String { impressions.formatted() }
  var clicksFormatted: String { clicks.formatted() }
  var adRequestsFormatted: String { adRequests.formatted() }
}

struct CountryStats: Identifiable {
  let id: String // COUNTRY dimension value
  let displayName: String
  let estimatedEarningsMicros: Int64
  let impressions: Int64
  let clicks: Int64
  let adRequests: Int64
  
  var estimatedEarningsFormatted: String {
    let units = Double(estimatedEarningsMicros) / 1_000_000.0
    return String(format: "%.2f", units)
  }
  
  var impressionsFormatted: String { impressions.formatted() }
  var clicksFormatted: String { clicks.formatted() }
  var adRequestsFormatted: String { adRequests.formatted() }
}

struct TimePeriodReport {
  let periodLabel: String
  let dateRange: String
  let currencyCode: String
  let totalStats: MTDReportSummary
  let appBreakdown: [AppStats]
  let countryBreakdown: [CountryStats]
}

struct MultiPeriodReport {
  let currencyCode: String
  let today: TimePeriodReport
  let yesterday: TimePeriodReport
  let last7Days: TimePeriodReport
  let last30Days: TimePeriodReport
}

// Payout entry represents estimated earnings for a given app and month.
struct PayoutEntry: Identifiable {
  let appId: String
  let appName: String
  let monthLabel: String // e.g. "2025-09" or display label
  let estimatedEarningsMicros: Int64
  var id: String { "\(appId)-\(monthLabel)" }
  var estimatedEarningsFormatted: String {
    let units = Double(estimatedEarningsMicros) / 1_000_000.0
    return String(format: "%.2f", units)
  }
}

struct DetailedReport {
  let dateRange: String
  let currencyCode: String
  let totalStats: MTDReportSummary
  let appBreakdown: [AppStats]
}

final class AdMobAPIClient {
  private let baseURL = URL(string: "https://admob.googleapis.com/v1")!

  func listAccounts(accessToken: String) async throws -> [PublisherAccount] {
    var req = URLRequest(url: baseURL.appending(path: "accounts"))
    req.httpMethod = "GET"
    req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, resp) = try await URLSession.shared.data(for: req)
    try Self.ensureOK(resp)

    let decoded = try JSONDecoder().decode(ListPublisherAccountsResponse.self, from: data)
    return decoded.account ?? []
  }

  func detailedReport(parentAccountName: String, dateRangeOption: DateRangeOption, accessToken: String) async throws -> DetailedReport {
    let (start, end) = dateRangeOption.dateRange()
    let cal = Calendar.current
    
    let startDC = cal.dateComponents([.year, .month, .day], from: start)
    let endDC = cal.dateComponents([.year, .month, .day], from: end)

    let requestBody = GenerateNetworkReportRequest(
      reportSpec: NetworkReportSpec(
        dateRange: DateRange(
          startDate: ReportDate(year: startDC.year ?? 2000, month: startDC.month ?? 1, day: startDC.day ?? 1),
          endDate: ReportDate(year: endDC.year ?? 2000, month: endDC.month ?? 1, day: endDC.day ?? 1)
        ),
        dimensions: ["APP"], // Break down by app
        metrics: ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS", "AD_REQUESTS"],
        localizationSettings: LocalizationSettings(currencyCode: nil, languageCode: "en-US")
      )
    )

    var req = URLRequest(url: baseURL.appending(path: "\(parentAccountName)/networkReport:generate"))
    req.httpMethod = "POST"
    req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(requestBody)

    let (data, resp) = try await URLSession.shared.data(for: req)
    try Self.ensureOK(resp)

    let stream = try JSONDecoder().decode([GenerateNetworkReportResponse].self, from: data)

    let currency = stream.compactMap { $0.header?.localizationSettings?.currencyCode }.first ?? ""
    let headerRange = stream.compactMap { $0.header?.dateRange }.first

    let rows = stream.compactMap { $0.row }
    
    var appBreakdown: [AppStats] = []
    var totalEarnings: Int64 = 0
    var totalImpressions: Int64 = 0
    var totalClicks: Int64 = 0
    var totalRequests: Int64 = 0
    
    for row in rows {
      let appValue = row.dimensionValues?["APP"]?.value ?? "Unknown"
      let appName = row.dimensionValues?["APP"]?.displayLabel ?? appValue
      let metrics = row.metricValues ?? [:]
      
      let earnings = Int64(metrics["ESTIMATED_EARNINGS"]?.microsValue ?? "0") ?? 0
      let impressions = Int64(metrics["IMPRESSIONS"]?.integerValue ?? "0") ?? 0
      let clicks = Int64(metrics["CLICKS"]?.integerValue ?? "0") ?? 0
      let requests = Int64(metrics["AD_REQUESTS"]?.integerValue ?? "0") ?? 0
      
      totalEarnings += earnings
      totalImpressions += impressions
      totalClicks += clicks
      totalRequests += requests
      
      appBreakdown.append(AppStats(
        id: appValue,
        displayName: appName,
        estimatedEarningsMicros: earnings,
        impressions: impressions,
        clicks: clicks,
        adRequests: requests
      ))
    }
    
    // Sort by earnings descending
    appBreakdown.sort { $0.estimatedEarningsMicros > $1.estimatedEarningsMicros }

    let rangeString: String = {
      guard let hr = headerRange, let s = hr.startDate, let e = hr.endDate else {
        return dateRangeOption.rawValue
      }
      return String(format: "%04d-%02d-%02d → %04d-%02d-%02d", s.year, s.month, s.day, e.year, e.month, e.day)
    }()

    let totalStats = MTDReportSummary(
      dateRange: rangeString,
      currencyCode: currency,
      estimatedEarningsMicros: totalEarnings,
      impressions: totalImpressions,
      clicks: totalClicks,
      adRequests: totalRequests
    )
    
    return DetailedReport(
      dateRange: rangeString,
      currencyCode: currency,
      totalStats: totalStats,
      appBreakdown: appBreakdown
    )
  }

  /// Fetch a report for a specific time period with both APP and COUNTRY breakdowns
  func timePeriodReport(
    parentAccountName: String,
    periodLabel: String,
    startDate: Date,
    endDate: Date,
    accessToken: String
  ) async throws -> TimePeriodReport {
    let cal = Calendar.current
    let startDC = cal.dateComponents([.year, .month, .day], from: startDate)
    let endDC = cal.dateComponents([.year, .month, .day], from: endDate)
    
    // Fetch APP breakdown
    let appBreakdown = try await fetchBreakdown(
      parentAccountName: parentAccountName,
      dimension: "APP",
      startDC: startDC,
      endDC: endDC,
      accessToken: accessToken
    )
    
    // Fetch COUNTRY breakdown
    let countryBreakdown = try await fetchBreakdown(
      parentAccountName: parentAccountName,
      dimension: "COUNTRY",
      startDC: startDC,
      endDC: endDC,
      accessToken: accessToken
    )
    
    // Calculate totals from app breakdown
    var totalEarnings: Int64 = 0
    var totalImpressions: Int64 = 0
    var totalClicks: Int64 = 0
    var totalRequests: Int64 = 0
    
    for app in appBreakdown.apps {
      totalEarnings += app.estimatedEarningsMicros
      totalImpressions += app.impressions
      totalClicks += app.clicks
      totalRequests += app.adRequests
    }
    
    let rangeString = String(format: "%04d-%02d-%02d → %04d-%02d-%02d",
                            startDC.year ?? 2000, startDC.month ?? 1, startDC.day ?? 1,
                            endDC.year ?? 2000, endDC.month ?? 1, endDC.day ?? 1)
    
    let totalStats = MTDReportSummary(
      dateRange: rangeString,
      currencyCode: appBreakdown.currency,
      estimatedEarningsMicros: totalEarnings,
      impressions: totalImpressions,
      clicks: totalClicks,
      adRequests: totalRequests
    )
    
    return TimePeriodReport(
      periodLabel: periodLabel,
      dateRange: rangeString,
      currencyCode: appBreakdown.currency,
      totalStats: totalStats,
      appBreakdown: appBreakdown.apps,
      countryBreakdown: countryBreakdown.countries
    )
  }
  
  private struct BreakdownResult {
    let currency: String
    let apps: [AppStats]
    let countries: [CountryStats]
  }
  
  private func fetchBreakdown(
    parentAccountName: String,
    dimension: String,
    startDC: DateComponents,
    endDC: DateComponents,
    accessToken: String
  ) async throws -> BreakdownResult {
    let requestBody = GenerateNetworkReportRequest(
      reportSpec: NetworkReportSpec(
        dateRange: DateRange(
          startDate: ReportDate(year: startDC.year ?? 2000, month: startDC.month ?? 1, day: startDC.day ?? 1),
          endDate: ReportDate(year: endDC.year ?? 2000, month: endDC.month ?? 1, day: endDC.day ?? 1)
        ),
        dimensions: [dimension],
        metrics: ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS", "AD_REQUESTS"],
        localizationSettings: LocalizationSettings(currencyCode: nil, languageCode: "en-US")
      )
    )
    
    var req = URLRequest(url: baseURL.appending(path: "\(parentAccountName)/networkReport:generate"))
    req.httpMethod = "POST"
    req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(requestBody)
    
    let (data, resp) = try await URLSession.shared.data(for: req)
    try Self.ensureOK(resp)
    
    let stream = try JSONDecoder().decode([GenerateNetworkReportResponse].self, from: data)
    let currency = stream.compactMap { $0.header?.localizationSettings?.currencyCode }.first ?? ""
    let rows = stream.compactMap { $0.row }
    
    var apps: [AppStats] = []
    var countries: [CountryStats] = []
    
    for row in rows {
      let dimValue = row.dimensionValues?[dimension]?.value ?? "Unknown"
      let dimName = row.dimensionValues?[dimension]?.displayLabel ?? dimValue
      let metrics = row.metricValues ?? [:]
      
      let earnings = Int64(metrics["ESTIMATED_EARNINGS"]?.microsValue ?? "0") ?? 0
      let impressions = Int64(metrics["IMPRESSIONS"]?.integerValue ?? "0") ?? 0
      let clicks = Int64(metrics["CLICKS"]?.integerValue ?? "0") ?? 0
      let requests = Int64(metrics["AD_REQUESTS"]?.integerValue ?? "0") ?? 0
      
      if dimension == "APP" {
        apps.append(AppStats(
          id: dimValue,
          displayName: dimName,
          estimatedEarningsMicros: earnings,
          impressions: impressions,
          clicks: clicks,
          adRequests: requests
        ))
      } else if dimension == "COUNTRY" {
        countries.append(CountryStats(
          id: dimValue,
          displayName: dimName,
          estimatedEarningsMicros: earnings,
          impressions: impressions,
          clicks: clicks,
          adRequests: requests
        ))
      }
    }
    
    // Sort by earnings descending
    apps.sort { $0.estimatedEarningsMicros > $1.estimatedEarningsMicros }
    countries.sort { $0.estimatedEarningsMicros > $1.estimatedEarningsMicros }
    
    return BreakdownResult(currency: currency, apps: apps, countries: countries)
  }

  /// Fetch multi-period report with today, yesterday, last 7 days, and last 30 days
  func multiPeriodReport(parentAccountName: String, accessToken: String) async throws -> MultiPeriodReport {
    let cal = Calendar.current
    let now = Date()
    
    // Define date ranges
    let todayStart = cal.startOfDay(for: now)
    let todayEnd = now
    
    let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
    let yesterdayEnd = cal.date(byAdding: .second, value: -1, to: todayStart) ?? todayStart
    
    let last7Start = cal.date(byAdding: .day, value: -7, to: todayStart) ?? todayStart
    let last7End = now
    
    let last30Start = cal.date(byAdding: .day, value: -30, to: todayStart) ?? todayStart
    let last30End = now
    
    // Fetch all periods in parallel
    async let todayReport = timePeriodReport(
      parentAccountName: parentAccountName,
      periodLabel: "Today",
      startDate: todayStart,
      endDate: todayEnd,
      accessToken: accessToken
    )
    
    async let yesterdayReport = timePeriodReport(
      parentAccountName: parentAccountName,
      periodLabel: "Yesterday",
      startDate: yesterdayStart,
      endDate: yesterdayEnd,
      accessToken: accessToken
    )
    
    async let last7Report = timePeriodReport(
      parentAccountName: parentAccountName,
      periodLabel: "Last 7 Days",
      startDate: last7Start,
      endDate: last7End,
      accessToken: accessToken
    )
    
    async let last30Report = timePeriodReport(
      parentAccountName: parentAccountName,
      periodLabel: "Last 30 Days",
      startDate: last30Start,
      endDate: last30End,
      accessToken: accessToken
    )
    
    let (today, yesterday, last7, last30) = try await (todayReport, yesterdayReport, last7Report, last30Report)
    
    return MultiPeriodReport(
      currencyCode: today.currencyCode,
      today: today,
      yesterday: yesterday,
      last7Days: last7,
      last30Days: last30
    )
  }

  /// Retrieve estimated earnings by APP and MONTH for the last `months` months.
  func payoutHistory(parentAccountName: String, months: Int = 6, accessToken: String) async throws -> [PayoutEntry] {
    let cal = Calendar.current
    let end = Date()
    // If months <= 0 treat as "all time" and pick a safe early date, otherwise compute start as months ago
    let start: Date
    if months <= 0 {
      start = cal.date(from: DateComponents(year: 2010, month: 1, day: 1)) ?? end
    } else {
      // Start at the first day of the month `months - 1` months ago
      let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: end)) ?? end
      start = cal.date(byAdding: .month, value: -(months - 1), to: thisMonthStart) ?? thisMonthStart
    }

    let startDC = cal.dateComponents([.year, .month, .day], from: start)
    let endDC = cal.dateComponents([.year, .month, .day], from: end)

    let requestBody = GenerateNetworkReportRequest(
      reportSpec: NetworkReportSpec(
        dateRange: DateRange(
          startDate: ReportDate(year: startDC.year ?? 2000, month: startDC.month ?? 1, day: startDC.day ?? 1),
          endDate: ReportDate(year: endDC.year ?? 2000, month: endDC.month ?? 1, day: endDC.day ?? 1)
        ),
        dimensions: ["APP", "MONTH"],
        metrics: ["ESTIMATED_EARNINGS"],
        localizationSettings: LocalizationSettings(currencyCode: nil, languageCode: "en-US")
      )
    )

    var req = URLRequest(url: baseURL.appending(path: "\(parentAccountName)/networkReport:generate"))
    req.httpMethod = "POST"
    req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(requestBody)

    let (data, resp) = try await URLSession.shared.data(for: req)
    try Self.ensureOK(resp)

    let stream = try JSONDecoder().decode([GenerateNetworkReportResponse].self, from: data)
    let rows = stream.compactMap { $0.row }

    var entries: [PayoutEntry] = []
    for row in rows {
      let appId = row.dimensionValues?["APP"]?.value ?? "Unknown"
      let appName = row.dimensionValues?["APP"]?.displayLabel ?? appId
      let monthLabel = row.dimensionValues?["MONTH"]?.value ?? row.dimensionValues?["MONTH"]?.displayLabel ?? ""
      let metrics = row.metricValues ?? [:]
      let earnings = Int64(metrics["ESTIMATED_EARNINGS"]?.microsValue ?? "0") ?? 0
      entries.append(PayoutEntry(appId: appId, appName: appName, monthLabel: monthLabel, estimatedEarningsMicros: earnings))
    }

    // Sort by month desc then earnings desc
    entries.sort { lhs, rhs in
      if lhs.monthLabel == rhs.monthLabel { return lhs.estimatedEarningsMicros > rhs.estimatedEarningsMicros }
      return lhs.monthLabel > rhs.monthLabel
    }

    return entries
  }

  /// Returns aggregated estimated earnings (micros) and currency for the requested date range.
  func payoutTotal(parentAccountName: String, dateRangeOption: DateRangeOption, accessToken: String) async throws -> (micros: Int64, currency: String) {
    let (start, end) = dateRangeOption.dateRange()
    let cal = Calendar.current
    let startDC = cal.dateComponents([.year, .month, .day], from: start)
    let endDC = cal.dateComponents([.year, .month, .day], from: end)

    let requestBody = GenerateNetworkReportRequest(
      reportSpec: NetworkReportSpec(
        dateRange: DateRange(
          startDate: ReportDate(year: startDC.year ?? 2000, month: startDC.month ?? 1, day: startDC.day ?? 1),
          endDate: ReportDate(year: endDC.year ?? 2000, month: endDC.month ?? 1, day: endDC.day ?? 1)
        ),
        dimensions: nil,
        metrics: ["ESTIMATED_EARNINGS"],
        localizationSettings: LocalizationSettings(currencyCode: nil, languageCode: "en-US")
      )
    )

    var req = URLRequest(url: baseURL.appending(path: "\(parentAccountName)/networkReport:generate"))
    req.httpMethod = "POST"
    req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(requestBody)

    let (data, resp) = try await URLSession.shared.data(for: req)
    try Self.ensureOK(resp)

    let stream = try JSONDecoder().decode([GenerateNetworkReportResponse].self, from: data)

    let currency = stream.compactMap { $0.header?.localizationSettings?.currencyCode }.first ?? ""
    let rows = stream.compactMap { $0.row }

    // Sum earnings from all rows (should be single aggregated row when no dimensions).
    var total: Int64 = 0
    for row in rows {
      let metrics = row.metricValues ?? [:]
      let earnings = Int64(metrics["ESTIMATED_EARNINGS"]?.microsValue ?? "0") ?? 0
      total += earnings
    }

    return (micros: total, currency: currency)
  }

  private static func ensureOK(_ resp: URLResponse) throws {
    guard let http = resp as? HTTPURLResponse else { return }
    guard (200..<300).contains(http.statusCode) else {
      throw NSError(domain: "HTTP", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
    }
  }
}

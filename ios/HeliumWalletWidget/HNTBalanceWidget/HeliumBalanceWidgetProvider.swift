import Intents
import SwiftUI
import WidgetKit

struct BalanceWidgetData: Decodable {
    var hntPrice: Double
    var token: String
    var accountAddress: String
}

struct BalanceWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    var hntPrice: Double
    var hntDailyEarnings: Double
    var balance: Int
}

struct ParsedBalanceWidgetData {
    var total: Double
    var balance: Int
    var price: Double
}

// Helium Balance Widget Provider that determines placeholder, snapshot, and timeline for this widget.
struct HNTBalanceWidgetProvider: IntentTimelineProvider {
    func placeholder(in _: Context) -> BalanceWidgetEntry {
        BalanceWidgetEntry(date: Date(), configuration: ConfigurationIntent(), hntPrice: 50.41234, hntDailyEarnings: 54.37, balance: 1_500_000)
    }

    func getSnapshot(for _: ConfigurationIntent, in _: Context, completion: @escaping (BalanceWidgetEntry) -> Void) {
        let entry = BalanceWidgetEntry(date: Date(), configuration: ConfigurationIntent(), hntPrice: 50.41234, hntDailyEarnings: 54.37, balance: 1_500_000)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in _: Context, completion: @escaping (Timeline<BalanceWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.helium.mobile.wallet.widget")
        if userDefaults != nil {
            let entryDate = Date()
            if let savedData = userDefaults!.value(forKey: "heliumWalletWidgetKey") as? String {
                let decoder = JSONDecoder()
                let data = savedData.data(using: .utf8)
                if let parsedData = try? decoder.decode(HeliumWalletWidgetData.self, from: data!) {
                    // Fetch balance data from nova wallet API.
                    Network().fetchBalanceData(parsedWidgetData: parsedData) { error, parsedBalanceWidgetData in
                        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: entryDate)!

                        if error == nil {
                            let entry = BalanceWidgetEntry(date: nextRefresh, configuration: configuration, hntPrice: parsedBalanceWidgetData!.price, hntDailyEarnings: parsedBalanceWidgetData!.total, balance: parsedBalanceWidgetData!.balance)
                            let timeline = Timeline(entries: [entry], policy: .atEnd)
                            completion(timeline)
                        } else {
                            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: entryDate)!
                            let entry = BalanceWidgetEntry(date: nextRefresh, configuration: configuration, hntPrice: 0, hntDailyEarnings: 0, balance: 0)
                            let timeline = Timeline(entries: [entry], policy: .atEnd)
                            completion(timeline)
                        }
                    }
                }
            } else {
                let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: entryDate)!
                let entry = BalanceWidgetEntry(date: nextRefresh, configuration: configuration, hntPrice: 0, hntDailyEarnings: 0, balance: 0)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            }
        }
    }
}
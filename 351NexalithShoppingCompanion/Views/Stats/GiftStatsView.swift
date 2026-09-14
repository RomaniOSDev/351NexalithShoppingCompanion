import Charts
import SwiftUI

struct GiftStatsView: View {
    @EnvironmentObject private var store: GiftStore

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            if isEmpty {
                Spacer(minLength: 12)
                GiftEmptyState(
                    symbol: "chart.bar.fill",
                    message: "Add people, dates, and wrapped gifts to see trends."
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        metricsGrid
                        typeChartCard
                        wrappedChartCard
                        coverageCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Stats")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var isEmpty: Bool {
        store.giftProfiles.isEmpty && store.occasions.isEmpty && store.pastPurchases.isEmpty
    }

    private var metricsGrid: some View {
        let openIdeas = store.giftProfiles.filter { $0.hasGiftIdea && !$0.isPurchased }.count
        let wrapped = store.pastPurchases.count
        let upcoming = store.upcomingOccasions().count
        let dueSoon = store.occasions.filter { $0.date.isGiftDue(withinDays: 14) }.count

        let planned = store.plannedBudgetTotal()
        let spent = store.spentBudgetTotal()
        let given = store.giftProfiles.filter { $0.pipelineStatus == .given }.count

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricTile(title: "People", value: store.giftProfiles.count, symbol: "person.2.fill")
            metricTile(title: "Upcoming", value: upcoming, symbol: "calendar")
            metricTile(title: "Open ideas", value: openIdeas, symbol: "lightbulb.fill")
            metricTile(title: "Wrapped", value: wrapped, symbol: "gift.fill")
            metricTile(title: "Due soon", value: dueSoon, symbol: "bell.fill")
            metricTile(title: "Dates", value: store.occasions.count, symbol: "clock.fill")
            metricTile(title: "Given", value: given, symbol: "hand.thumbsup.fill")
            moneyTile(title: "Planned", value: planned, symbol: "banknote.fill")
            moneyTile(title: "Spent", value: spent, symbol: "cart.fill")
        }
    }

    private func metricTile(title: String, value: Int, symbol: String) -> some View {
        GiftTagCard(showsRibbon: false) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                Text("\(value)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundColor(Palette.text)
        }
    }

    private func moneyTile(title: String, value: Double, symbol: String) -> some View {
        GiftTagCard(showsRibbon: false) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                Text(GiftFormatters.money(value))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundColor(Palette.text)
        }
    }

    private var typeChartCard: some View {
        GiftTagCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Occasions by type")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                if typeSlices.allSatisfy({ $0.count == 0 }) {
                    Text("No dates yet.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.86))
                } else {
                    Chart(typeSlices) { slice in
                        BarMark(
                            x: .value("Type", slice.title),
                            y: .value("Count", slice.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.primary, Palette.accent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.92))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.88))
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var wrappedChartCard: some View {
        GiftTagCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Wrapped over 6 months")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                if monthSlices.allSatisfy({ $0.count == 0 }) {
                    Text("Mark gifts as purchased to see this trend.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.86))
                } else {
                    Chart(monthSlices) { slice in
                        LineMark(
                            x: .value("Month", slice.date, unit: .month),
                            y: .value("Wrapped", slice.count)
                        )
                        .foregroundStyle(Palette.primary)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        AreaMark(
                            x: .value("Month", slice.date, unit: .month),
                            y: .value("Wrapped", slice.count)
                        )
                        .foregroundStyle(Palette.accent.opacity(0.28))
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Month", slice.date, unit: .month),
                            y: .value("Wrapped", slice.count)
                        )
                        .foregroundStyle(Palette.primary)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .foregroundStyle(Color.white.opacity(0.92))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.88))
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var coverageCard: some View {
        let upcoming = store.upcomingOccasions()
        let withIdea = upcoming.filter { store.hasGiftIdea(for: $0) }.count
        let missing = max(upcoming.count - withIdea, 0)

        return GiftTagCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming coverage")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                if upcoming.isEmpty {
                    Text("No upcoming dates to cover.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.86))
                } else {
                    Chart(coverageSlices(withIdea: withIdea, missing: missing)) { slice in
                        BarMark(
                            x: .value("Count", slice.count),
                            y: .value("Status", slice.title)
                        )
                        .foregroundStyle(slice.id == "ready" ? Palette.primary : Palette.accent)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.88))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.92))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                    .frame(height: 120)
                    Text("\(withIdea) of \(upcoming.count) upcoming dates already have an idea.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.88))
                }
            }
        }
    }

    private var typeSlices: [StatSlice] {
        OccasionType.allCases.map { type in
            StatSlice(
                id: type.rawValue,
                title: type.title,
                count: store.occasions.filter { $0.occasionType == type }.count
            )
        }
    }

    private var monthSlices: [StatSlice] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).reversed().compactMap { offset -> StatSlice? in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
            guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
            let count = store.pastPurchases.filter { $0.date >= start && $0.date < end }.count
            return StatSlice(
                id: GiftFormatters.monthKey.string(from: start),
                title: GiftFormatters.month.string(from: start),
                count: count,
                date: start
            )
        }
    }

    private func coverageSlices(withIdea: Int, missing: Int) -> [StatSlice] {
        [
            StatSlice(id: "ready", title: "Has idea", count: withIdea),
            StatSlice(id: "missing", title: "Needs idea", count: missing)
        ]
    }
}

private struct StatSlice: Identifiable {
    let id: String
    let title: String
    let count: Int
    var date: Date = .distantPast
}

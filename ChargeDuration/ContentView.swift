import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: MeasurementStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingEndConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    batteryCard

                    if let measurement = store.currentMeasurement {
                        activeMeasurementCard(measurement)
                    } else {
                        startCard
                    }

                    explanationCard

                    if !store.history.isEmpty {
                        historySection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Charge Duration")
            .alert("End this measurement?", isPresented: $showingEndConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("End Measurement", role: .destructive) { store.endCurrentMeasurement() }
            } message: {
                Text("It will be saved in your history.")
            }
            .alert("Storage issue", isPresented: storageAlertBinding) {
                Button("OK") { store.persistenceError = nil }
            } message: {
                Text(store.persistenceError ?? "An unknown storage error occurred.")
            }
        }
        .onAppear { store.refreshAndRecord() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.refreshAndRecord()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            store.refreshAndRecord()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            store.refreshAndRecord()
        }
    }

    private var storageAlertBinding: Binding<Bool> {
        Binding(
            get: { store.persistenceError != nil },
            set: { if !$0 { store.persistenceError = nil } }
        )
    }

    private var batteryCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current battery")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(store.reading.percentage.map { "\($0)%" } ?? "Unavailable")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: batterySymbol)
                        .font(.system(size: 36))
                        .foregroundStyle(batteryColor)
                    Text(store.reading.state.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var startCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ready for a new charge")
                    .font(.title2.bold())
                Text("For the clearest result, unplug at 100%, then start the measurement.")
                    .foregroundStyle(.secondary)
                Button(action: { store.startNewMeasurement() }) {
                    Label("Start New Measurement", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.reading.percentage == nil)

                if store.reading.percentage == nil {
                    Text("Battery information is unavailable in the Simulator. Install on an iPhone to take measurements.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func activeMeasurementCard(_ measurement: ChargeMeasurement) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let liveElapsed = max(0, context.date.timeIntervalSince(measurement.startedAt))
            let currentPercentage = store.reading.percentage ?? measurement.effectiveEndPercentage
            let consumed = max(0, measurement.startingPercentage - currentPercentage)
            let totalEstimate = estimateTotal(elapsed: liveElapsed, consumed: consumed)
            let remainingEstimate = estimateRemaining(elapsed: liveElapsed, consumed: consumed, current: currentPercentage)

            Card {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label("Measurement in progress", systemImage: "timer")
                            .font(.headline)
                            .foregroundStyle(.tint)
                        Spacer()
                        Text("Started at \(measurement.startingPercentage)%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    metricGrid(
                        elapsed: liveElapsed,
                        consumed: consumed,
                        total: totalEstimate,
                        remaining: remainingEstimate
                    )

                    if consumed < 10 {
                        Label(
                            "Use at least \(10 - consumed) more percentage point\(10 - consumed == 1 ? "" : "s") to see an estimate. More data produces a better estimate.",
                            systemImage: "chart.line.uptrend.xyaxis"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button("End Measurement", role: .destructive) {
                            showingEndConfirmation = true
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("End & Start New") {
                            store.startNewMeasurement()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.reading.percentage == nil)
                    }
                }
            }
        }
    }

    private func metricGrid(elapsed: TimeInterval, consumed: Int, total: TimeInterval?, remaining: TimeInterval?) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 18) {
            GridRow {
                MetricView(title: "Elapsed", value: elapsed.durationText)
                MetricView(title: "Consumed", value: "\(consumed)%")
            }
            GridRow {
                MetricView(title: "Est. full duration", value: total?.durationText ?? "—")
                MetricView(title: "Est. remaining", value: remaining?.durationText ?? "—")
            }
        }
    }

    private var explanationCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label("How the estimate works", systemImage: "info.circle.fill")
                    .font(.headline)
                Text("The estimate assumes your future use resembles your use since this measurement began. A full-duration estimate is elapsed time divided by the fraction of battery consumed. Results vary with screen time, apps, signal strength, temperature, and battery health.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.title2.bold())
                .padding(.horizontal, 4)

            ForEach(store.history) { measurement in
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(measurement.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                            Spacer()
                            Text("\(measurement.startingPercentage)% → \(measurement.effectiveEndPercentage)%")
                                .font(.subheadline.weight(.semibold))
                        }
                        HStack(spacing: 22) {
                            MetricView(title: "Measured", value: measurement.elapsed.durationText, compact: true)
                            MetricView(title: "Consumed", value: "\(measurement.percentageConsumed)%", compact: true)
                            MetricView(title: "Est. full", value: measurement.estimatedTotalDuration?.durationText ?? "Not enough data", compact: true)
                        }
                    }
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if let index = store.history.firstIndex(where: { $0.id == measurement.id }) {
                            store.deleteHistory(at: IndexSet(integer: index))
                        }
                    }
                }
            }
            Text("Touch and hold a history item to delete it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var batterySymbol: String {
        switch store.reading.state {
        case .charging: "battery.75percent.bolt"
        case .full: "battery.100percent"
        case .unplugged, .unknown: "battery.50percent"
        }
    }

    private var batteryColor: Color {
        switch store.reading.state {
        case .charging, .full: .green
        case .unplugged, .unknown: .primary
        }
    }

    private func estimateTotal(elapsed: TimeInterval, consumed: Int) -> TimeInterval? {
        guard consumed >= 10, elapsed > 0 else { return nil }
        return elapsed / (Double(consumed) / 100)
    }

    private func estimateRemaining(elapsed: TimeInterval, consumed: Int, current: Int) -> TimeInterval? {
        guard consumed >= 10, elapsed > 0 else { return nil }
        return elapsed / Double(consumed) * Double(current)
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct MetricView: View {
    let title: String
    let value: String
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(compact ? .subheadline.bold() : .title3.bold())
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension TimeInterval {
    var durationText: String {
        let totalMinutes = max(0, Int(self) / 60)
        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if totalMinutes > 0 { return "\(minutes)m" }
        return "<1m"
    }
}

#Preview {
    ContentView()
        .environmentObject(MeasurementStore())
}

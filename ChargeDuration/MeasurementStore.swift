import Foundation

@MainActor
final class MeasurementStore: ObservableObject {
    @Published private(set) var currentMeasurement: ChargeMeasurement?
    @Published private(set) var history: [ChargeMeasurement] = []
    @Published private(set) var reading = BatteryReading(percentage: nil, state: .unknown)
    @Published var persistenceError: String?

    private let batteryMonitor = BatteryMonitor()
    private let fileManager: FileManager
    private let storageURL: URL

    private struct StoredData: Codable {
        var currentMeasurement: ChargeMeasurement?
        var history: [ChargeMeasurement]
    }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = applicationSupport.appendingPathComponent("ChargeDuration", isDirectory: true)
        self.storageURL = appDirectory.appendingPathComponent("measurements.json")
        load()
        refreshAndRecord()
    }

    func refreshAndRecord(at date: Date = .now) {
        reading = batteryMonitor.currentReading()
        guard let percentage = reading.percentage, var measurement = currentMeasurement else { return }

        let last = measurement.samples.last
        // A fresh launch/activation is always captured. Closely repeated lifecycle callbacks
        // are collapsed so they do not fill the file with duplicate samples.
        if let last, date.timeIntervalSince(last.date) < 2, last.percentage == percentage {
            return
        }

        measurement.samples.append(BatterySample(date: date, percentage: percentage))
        currentMeasurement = measurement
        save()
    }

    func startNewMeasurement(at date: Date = .now) {
        guard let percentage = reading.percentage else { return }
        if currentMeasurement != nil {
            endCurrentMeasurement(at: date)
        }

        currentMeasurement = ChargeMeasurement(
            startedAt: date,
            startingPercentage: percentage,
            samples: [BatterySample(date: date, percentage: percentage)]
        )
        save()
    }

    func endCurrentMeasurement(at date: Date = .now) {
        guard var measurement = currentMeasurement else { return }
        let percentage = reading.percentage ?? measurement.latestSample?.percentage ?? measurement.startingPercentage
        measurement.samples.append(BatterySample(date: date, percentage: percentage))
        measurement.endedAt = date
        measurement.endingPercentage = percentage
        history.insert(measurement, at: 0)
        currentMeasurement = nil
        save()
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let stored = try JSONDecoder().decode(StoredData.self, from: data)
            currentMeasurement = stored.currentMeasurement
            history = stored.history
        } catch {
            persistenceError = "Saved measurements could not be read. New measurements can still be recorded."
        }
    }

    private func save() {
        do {
            let directory = storageURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(StoredData(currentMeasurement: currentMeasurement, history: history))
            try data.write(to: storageURL, options: .atomic)
            persistenceError = nil
        } catch {
            persistenceError = "This measurement could not be saved."
        }
    }
}

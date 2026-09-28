import Foundation

struct BatterySample: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let percentage: Int

    init(id: UUID = UUID(), date: Date, percentage: Int) {
        self.id = id
        self.date = date
        self.percentage = percentage
    }
}

struct ChargeMeasurement: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let startingPercentage: Int
    var samples: [BatterySample]
    var endedAt: Date?
    var endingPercentage: Int?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        startingPercentage: Int,
        samples: [BatterySample],
        endedAt: Date? = nil,
        endingPercentage: Int? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.startingPercentage = startingPercentage
        self.samples = samples
        self.endedAt = endedAt
        self.endingPercentage = endingPercentage
    }

    var latestSample: BatterySample? { samples.last }

    var effectiveEndDate: Date { endedAt ?? latestSample?.date ?? startedAt }

    var effectiveEndPercentage: Int { endingPercentage ?? latestSample?.percentage ?? startingPercentage }

    var elapsed: TimeInterval { max(0, effectiveEndDate.timeIntervalSince(startedAt)) }

    var percentageConsumed: Int { max(0, startingPercentage - effectiveEndPercentage) }

    var estimatedTotalDuration: TimeInterval? {
        guard percentageConsumed >= 10, elapsed > 0 else { return nil }
        return elapsed / (Double(percentageConsumed) / 100.0)
    }

    var estimatedTimeRemaining: TimeInterval? {
        guard percentageConsumed >= 10, elapsed > 0 else { return nil }
        let secondsPerPoint = elapsed / Double(percentageConsumed)
        return secondsPerPoint * Double(effectiveEndPercentage)
    }
}

enum ChargingState: String {
    case charging = "Charging"
    case full = "Full"
    case unplugged = "Not charging"
    case unknown = "Unknown"
}

struct BatteryReading: Equatable {
    let percentage: Int?
    let state: ChargingState
}

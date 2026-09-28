import UIKit

@MainActor
final class BatteryMonitor {
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    func currentReading() -> BatteryReading {
        let device = UIDevice.current
        let percentage: Int?

        if device.batteryLevel < 0 {
            percentage = nil
        } else {
            percentage = min(100, max(0, Int((device.batteryLevel * 100).rounded())))
        }

        let state: ChargingState = switch device.batteryState {
        case .charging: .charging
        case .full: .full
        case .unplugged: .unplugged
        case .unknown: .unknown
        @unknown default: .unknown
        }

        return BatteryReading(percentage: percentage, state: state)
    }
}

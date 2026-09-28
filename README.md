# Charge Duration

Charge Duration is a simple iPhone app that estimates how long a full battery charge will last based on how you actually use your phone. You do not need to write down battery levels, note times, or perform any calculations.

The app reads the battery percentage and charging state supplied by iOS. Measurements and history are stored only on the iPhone.

## How to use the app

For the most useful result:

1. Charge the iPhone to 100%.
2. Unplug it from the charger.
3. Open Charge Duration.
4. Tap **Start New Measurement**.
5. Use the iPhone normally throughout the day.
6. Open Charge Duration whenever you want to see the latest result. The app automatically records the current time and battery percentage whenever it becomes active.
7. Tap **End Measurement** when you are finished. The result is saved in **History**.

You can start below 100%, but beginning at 100% makes the measurement easier to understand and compare with previous results.

## What the app displays

During a measurement, Charge Duration shows:

- **Current battery:** The latest battery percentage reported by iOS.
- **Elapsed:** How long it has been since you started the measurement.
- **Consumed:** The number of battery percentage points used since the start.
- **Estimated full duration:** How long a charge would last from 100% to 0% at the measured usage rate.
- **Estimated remaining:** How much longer the current battery level could last at that same rate.

The app waits until at least 10 percentage points have been consumed before showing estimates. A short measurement can be heavily affected by one activity, so collecting more data generally produces a more representative estimate.

## How the estimate works

The estimated full duration is calculated as:

`elapsed time ÷ fraction of battery consumed`

For example, if the phone consumes 20% in 2 hours, the estimated full duration is 10 hours.

This is an estimate, not a prediction guaranteed by iOS. It assumes future phone use resembles use since the measurement began. Screen brightness, games, video, navigation, cellular signal, temperature, background activity, and battery health can all change the result.

If you recharge during a measurement, the result may no longer represent one continuous discharge. End that measurement and tap **Start New Measurement** after unplugging for a cleaner result.

## Ending or restarting a measurement

- Tap **End Measurement** to finish and save the current measurement in History.
- Tap **End & Start New** to save the current measurement and immediately begin another one using the present battery level.
- Touch and hold a History item, then tap **Delete**, to remove it.

## Install the app on an iPhone

1. On a Mac with Xcode installed, open `ChargeDuration.xcodeproj`.
2. Select the **ChargeDuration** project in the left sidebar and then select the **ChargeDuration** target.
3. Open **Signing & Capabilities** and choose your Apple Developer **Team**.
4. If Xcode says the bundle identifier is unavailable, replace it with a unique value such as `com.yourname.ChargeDuration`.
5. Connect and unlock your iPhone. Tap **Trust** if either device asks you to trust the other.
6. Select your iPhone from Xcode's device menu.
7. Press the Run button or use `Command-R`.
8. If requested, enable **Developer Mode** under **Settings > Privacy & Security > Developer Mode** on the iPhone, then run the app again.

A free Apple ID can be used for personal testing, although Xcode may require the app to be signed and installed again periodically.

## Testing notes

The iOS Simulator does not provide a real battery reading. Charge Duration therefore shows the battery as unavailable and disables its start button in the Simulator. Install the app on a physical iPhone to test measurements.

## Privacy

Charge Duration has:

- No user accounts
- No analytics or advertising
- No cloud synchronization
- No external services or third-party packages
- No network features

All measurement data is stored in the app's private local storage. Deleting Charge Duration from the iPhone also deletes its saved measurements.

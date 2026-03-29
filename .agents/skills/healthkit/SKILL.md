---
name: "healthkit"
description: "Use when implementing health data features. Covers HealthKit authorization, statistics queries, sample queries, sleep analysis, common types."
---

# HealthKit Integration

Use this guide when implementing or modifying HealthKit features.

## Setup Requirements
- `import HealthKit`
- Check availability: `HKHealthStore.isHealthDataAvailable()`
- Request authorization: `healthStore.requestAuthorization(toShare:read:)`
- Required Info.plist keys: `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription`
- Required entitlement: `com.apple.developer.healthkit`

## Authorization Flow
```swift
let store = HKHealthStore()
let readTypes: Set<HKObjectType> = [
    HKObjectType.quantityType(forIdentifier: .stepCount)!,
    HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
]

try await store.requestAuthorization(toShare: [], read: readTypes)
```

## Query Patterns

### Statistics Query (aggregated data)
```swift
let stepsType = HKQuantityType(.stepCount)
let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
let query = HKStatisticsQuery(
    quantityType: stepsType,
    quantitySamplePredicate: predicate,
    options: .cumulativeSum
) { _, statistics, _ in
    let sum = statistics?.sumQuantity()?.doubleValue(for: .count())
}
store.execute(query)
```

### Sample Query (individual records)
```swift
let query = HKSampleQuery(
    sampleType: sleepType,
    predicate: predicate,
    limit: HKObjectQueryNoLimit,
    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
) { _, results, _ in
    let samples = results as? [HKCategorySample] ?? []
}
store.execute(query)
```

## Common Types
| Type | Identifier | Unit |
|------|-----------|------|
| Steps | `.stepCount` | `.count()` |
| Heart Rate | `.heartRate` | `.count().unitDivided(by: .minute())` |
| HRV | `.heartRateVariabilitySDNN` | `.secondUnit(with: .milli)` |
| Active Energy | `.activeEnergyBurned` | `.kilocalorie()` |
| Sleep | `.sleepAnalysis` | Category (not quantity) |

## Sleep Analysis Values
- `.asleepCore`, `.asleepDeep`, `.asleepREM`, `.asleepUnspecified` — actual sleep
- `.inBed` — in bed but not necessarily asleep
- Filter for `asleep*` values when calculating sleep duration

## Rules
- Always check `HKHealthStore.isHealthDataAvailable()` before any operation
- Wrap HealthKit queries in `async/await` using `withCheckedContinuation`
- Service class must be `@MainActor @Observable` per project conventions
- Use `Loadable<T>` for async health data state

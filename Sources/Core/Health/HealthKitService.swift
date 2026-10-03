import Foundation
import HealthKit

final class HealthKitService: HealthDataProviding {
    private let store = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]
        try await store.requestAuthorization(toShare: [], read: types)
    }

    // MARK: - Workouts

    func recentWorkouts(days: Int) async throws -> [WorkoutSummary] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }

        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let timePred = HKQuery.predicateForSamples(withStart: start, end: nil, options: .strictStartDate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate<HKWorkout>.workout(timePred)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )
        let workouts = try await descriptor.result(for: store)
        return workouts.compactMap(summary(from:))
    }

    private func summary(from workout: HKWorkout) -> WorkoutSummary? {
        let type: WorkoutActivityType
        switch workout.workoutActivityType {
        case .running: type = .running
        case .hiking:  type = .hiking
        default:       return nil
        }

        let distType = HKQuantityType(.distanceWalkingRunning)
        // Preferência: statistics(for:) — API moderna. Garmin pode gravar apenas totalDistance.
        let km: Double
        if let statKm = workout.statistics(for: distType)?
            .sumQuantity()?
            .doubleValue(for: .meterUnit(with: .kilo)), statKm > 0 {
            km = statKm
        } else {
            km = workout.totalDistance?   // fallback para dados legados/Garmin
                .doubleValue(for: .meterUnit(with: .kilo)) ?? 0
        }
        guard km > 3 else { return nil }

        return WorkoutSummary(start: workout.startDate, end: workout.endDate,
                              distanceKm: km, activityType: type)
    }

    // MARK: - Sleep

    func lastNightSleepHours(reference: Date) async throws -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: reference)
        // Janela: 18h de ontem (dayStart - 6h) até 12h de hoje (dayStart + 12h)
        guard let windowStart = cal.date(byAdding: .hour, value: -6, to: dayStart),
              let windowEnd   = cal.date(byAdding: .hour, value: 12, to: dayStart) else {
            return nil
        }
        let timePred = HKQuery.predicateForSamples(
            withStart: windowStart, end: windowEnd, options: .strictStartDate
        )
        let sleepType = HKCategoryType(.sleepAnalysis)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate<HKCategorySample>.categorySample(
                type: sleepType, predicate: timePred
            )],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        let samples = try await descriptor.result(for: store)

        // Apenas estágios de sono real (ignorar inBed e awake)
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]

        let intervals = samples
            .filter { asleepValues.contains($0.value) }
            .map { DateInterval(start: $0.startDate, end: $0.endDate) }

        return SleepCalculator.totalHours(from: intervals)
    }

    // MARK: - Observer

    func startObserving(onChange: @escaping () -> Void) {
        let workoutType = HKObjectType.workoutType()
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) {
            _, completionHandler, error in
            defer { completionHandler() }
            guard error == nil else { return }
            DispatchQueue.main.async { onChange() }
        }
        store.execute(query)
        observerQuery = query
        store.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }
    }
}

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
            HKQuantityType(.stepCount),
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

    // MARK: - External data signal

    /// True para fontes externas ao iPhone nativo:
    /// - bundle ID que NÃO começa com "com.apple.health" (Garmin, Strava, etc.)
    /// - OU productType começando com "Watch" (Apple Watch)
    static func isExternalSource(bundleID: String, productType: String?) -> Bool {
        !bundleID.hasPrefix("com.apple.health") || productType?.hasPrefix("Watch") == true
    }

    func lastExternalDataDate(within days: Int) async throws -> Date? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let timePred = HKQuery.predicateForSamples(
            withStart: start, end: nil, options: .strictStartDate
        )
        let stepType = HKQuantityType(.stepCount)

        // Passo 1: descobrir quais fontes gravaram stepCount no janelo de tempo.
        // HKSourceQuery respeita o predicado de tempo e devolve exatamente as fontes
        // com dados no período — sem precisar paginar amostras do iPhone para achar o Garmin.
        let allSources: Set<HKSource> = try await withCheckedThrowingContinuation { cont in
            let q = HKSourceQuery(sampleType: stepType, samplePredicate: timePred) { _, sources, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: sources ?? [])
            }
            store.execute(q)
        }

        // Passo 2: fontes com bundle ID diferente de "com.apple.health" são externas (Garmin, Strava…).
        var externalSources = allSources.filter {
            !$0.bundleIdentifier.hasPrefix("com.apple.health")
        }

        // Passo 3: detectar Apple Watch entre as fontes "com.apple.health.*".
        // A distinção iPhone vs Watch é feita pelo productType em HKSourceRevision.
        let appleSources = allSources.filter { $0.bundleIdentifier.hasPrefix("com.apple.health") }
        if !appleSources.isEmpty {
            let srcPred = HKQuery.predicateForObjects(from: appleSources)
            let combined = NSCompoundPredicate(
                andPredicateWithSubpredicates: [timePred, srcPred]
            )
            let descriptor = HKSampleQueryDescriptor(
                predicates: [HKSamplePredicate<HKQuantitySample>.quantitySample(
                    type: stepType, predicate: combined
                )],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 10
            )
            let appleSamples = (try? await descriptor.result(for: store)) ?? []
            for sample in appleSamples
            where HealthKitService.isExternalSource(
                bundleID: sample.sourceRevision.source.bundleIdentifier,
                productType: sample.sourceRevision.productType
            ) {
                externalSources.insert(sample.sourceRevision.source)
            }
        }

        guard !externalSources.isEmpty else { return nil }

        // Passo 4: data da amostra mais recente entre as fontes externas.
        let extPred = NSCompoundPredicate(andPredicateWithSubpredicates: [
            timePred,
            HKQuery.predicateForObjects(from: externalSources),
        ])
        let finalDescriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate<HKQuantitySample>.quantitySample(
                type: stepType, predicate: extPred
            )],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let result = try await finalDescriptor.result(for: store)
        return result.first?.endDate
    }

    // MARK: - Observer

    func startObserving(onChange: @escaping () async -> Void) {
        let workoutType = HKObjectType.workoutType()
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) {
            _, completionHandler, error in
            guard error == nil else { completionHandler(); return }
            // Await onChange antes de chamar completionHandler — evita suspensão prematura pelo iOS.
            Task {
                await onChange()
                completionHandler()
            }
        }
        store.execute(query)
        observerQuery = query
        store.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }
    }
}

//
//  TimeLearningStore.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/10/26.
//

import Foundation

struct LearnStats: Codable {
    var ewmaMinutes: Double
    var samples: Int
    var lastUpdated: Date
}

/// Simple in-memory + UserDefaults persistence.
/// Swap to CoreData/SQLite later if you want.
@MainActor
final class TimeLearningStore: ObservableObject {
    @Published private(set) var statsByKey: [String: LearnStats] = [:]

    private let defaultsKey = "time_learning_stats_v1"

    init() {
        load()
    }

    func predictedMinutes(forKey key: String) -> Int? {
        guard let s = statsByKey[key], s.samples > 0 else { return nil }
        return max(5, Int(round(s.ewmaMinutes)))
    }

    func recordCompletion(
        key rawKey: String,
        actualMinutes: Int,
        alpha: Double = 0.25
    ) {
        let key = rawKey.normalizedLearnKey()
        let actual = Double(max(1, actualMinutes))

        if var s = statsByKey[key] {
            // EWMA update
            s.ewmaMinutes = alpha * actual + (1.0 - alpha) * s.ewmaMinutes
            s.samples += 1
            s.lastUpdated = Date()
            statsByKey[key] = s
        } else {
            statsByKey[key] = LearnStats(
                ewmaMinutes: actual,
                samples: 1,
                lastUpdated: Date()
            )
        }

        save()
    }

    func seedIfMissing(key rawKey: String, minutes: Int) {
        let key = rawKey.normalizedLearnKey()
        guard statsByKey[key] == nil else { return }
        statsByKey[key] = LearnStats(
            ewmaMinutes: Double(minutes),
            samples: 0,
            lastUpdated: Date()
        )
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            statsByKey = try JSONDecoder().decode([String: LearnStats].self, from: data)
        } catch {
            statsByKey = [:]
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(statsByKey)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            // ignore
        }
    }
}


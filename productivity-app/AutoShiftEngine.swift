//
//  AutoShiftEngine.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/10/26.
//

import Foundation

struct ShiftResult {
    var blocks: [ScheduleBlock]
    var appliedOverrunMin: Int
    var conflicts: [Conflict]
    var suggestions: [Suggestion]
}

struct Conflict: Identifiable {
    let id = UUID()
    let a: ScheduleBlock
    let b: ScheduleBlock
}

enum SuggestionKind {
    case shrinkBuffers(blockId: UUID, minutes: Int)
    case shortenBlock(blockId: UUID, minutes: Int)
    case moveBlock(blockId: UUID, newStartMin: Int)
    case spillToTomorrow(blockId: UUID, spillMinutes: Int)
}

struct Suggestion: Identifiable {
    let id = UUID()
    let title: String
    let kind: SuggestionKind
}

struct AutoShiftEngine {

    /// Apply "ran late" to the schedule.
    /// - Parameters:
    ///   - blocks: blocks for the day
    ///   - lateBlockId: the block that ran late
    ///   - actualEndMin: actual end time (minutes from midnight)
    static func applyLate(
        blocks: [ScheduleBlock],
        lateBlockId: UUID,
        actualEndMin: Int
    ) -> ShiftResult {

        var sorted = blocks.sorted { $0.startMin < $1.startMin }

        guard let idx = sorted.firstIndex(where: { $0.id == lateBlockId }) else {
            return ShiftResult(blocks: sorted, appliedOverrunMin: 0, conflicts: [], suggestions: [])
        }

        let lateBlock = sorted[idx]
        let overrun = max(0, actualEndMin - lateBlock.endMin)

        guard overrun > 0 else {
            return ShiftResult(blocks: sorted, appliedOverrunMin: 0, conflicts: [], suggestions: [])
        }

        // Step 1: Update the late block's duration so its end matches actualEndMin
        sorted[idx].durationMin = max(1, actualEndMin - lateBlock.startMin)

        // Step 2: Shift subsequent blocks when allowed
        var carry = overrun
        for i in (idx + 1)..<sorted.count {
            // Stop at fixed blocks: we can't push them without breaking reality.
            if sorted[i].flex == .fixed {
                break
            }

            // Shift semi/flexible blocks forward
            sorted[i].startMin += carry
        }

        // Step 3: Detect conflicts created with fixed blocks (or edge cases)
        let conflicts = findConflicts(sorted)

        // Step 4: Create suggestions (non-destructive)
        let suggestions = buildSuggestions(from: sorted, conflicts: conflicts)

        return ShiftResult(
            blocks: sorted.sorted { $0.startMin < $1.startMin },
            appliedOverrunMin: overrun,
            conflicts: conflicts,
            suggestions: suggestions
        )
    }

    static func findConflicts(_ blocks: [ScheduleBlock]) -> [Conflict] {
        var out: [Conflict] = []
        let sorted = blocks.sorted { $0.startMin < $1.startMin }

        for i in 0..<sorted.count {
            for j in (i+1)..<sorted.count {
                // early exit if no possible overlap
                if sorted[j].startMin >= sorted[i].endMin { break }
                if sorted[i].overlaps(with: sorted[j]) {
                    out.append(Conflict(a: sorted[i], b: sorted[j]))
                }
            }
        }
        return out
    }

    static func buildSuggestions(from blocks: [ScheduleBlock], conflicts: [Conflict]) -> [Suggestion] {
        guard !conflicts.isEmpty else { return [] }

        var suggestions: [Suggestion] = []

        // For each conflict, suggest actions for the more-flexible block first
        for c in conflicts {
            let (moreFlex, other) = chooseMoreFlexible(c.a, c.b)

            // 1) shrink buffers
            let shrinkable = moreFlex.bufferBeforeMin + moreFlex.bufferAfterMin
            if shrinkable > 0 {
                let mins = min(shrinkable, 10)
                suggestions.append(
                    Suggestion(
                        title: "Shrink buffers on “\(moreFlex.title)” by \(mins) min",
                        kind: .shrinkBuffers(blockId: moreFlex.id, minutes: mins)
                    )
                )
            }

            // 2) shorten flexible task blocks (not events)
            if moreFlex.kind == .task || moreFlex.kind == .focus {
                let mins = min(10, max(0, moreFlex.durationMin - 5))
                if mins > 0 {
                    suggestions.append(
                        Suggestion(
                            title: "Shorten “\(moreFlex.title)” by \(mins) min",
                            kind: .shortenBlock(blockId: moreFlex.id, minutes: mins)
                        )
                    )
                }
            }

            // 3) move to after the other block ends
            suggestions.append(
                Suggestion(
                    title: "Move “\(moreFlex.title)” to \(formatTime(other.endMin))",
                    kind: .moveBlock(blockId: moreFlex.id, newStartMin: other.endMin)
                )
            )

            // 4) spill to tomorrow (if the day is packed)
            suggestions.append(
                Suggestion(
                    title: "Spill part of “\(moreFlex.title)” to tomorrow",
                    kind: .spillToTomorrow(blockId: moreFlex.id, spillMinutes: min(30, moreFlex.durationMin))
                )
            )
        }

        // Deduplicate by (kind + block) roughly
        return suggestions
    }

    private static func chooseMoreFlexible(_ a: ScheduleBlock, _ b: ScheduleBlock) -> (ScheduleBlock, ScheduleBlock) {
        func score(_ f: FlexLevel) -> Int {
            switch f {
            case .fixed: return 0
            case .semiFlex: return 1
            case .flexible: return 2
            }
        }
        return score(a.flex) >= score(b.flex) ? (a, b) : (b, a)
    }

    static func formatTime(_ minutesFromMidnight: Int) -> String {
        let m = max(0, minutesFromMidnight)
        let h = (m / 60) % 24
        let min = m % 60
        let isPM = h >= 12
        let hr12 = ((h + 11) % 12) + 1
        return String(format: "%d:%02d %@", hr12, min, isPM ? "PM" : "AM")
    }
}

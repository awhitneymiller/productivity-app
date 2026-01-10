//
//  SchedulingModels.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/10/26.
//

import Foundation

enum BlockKind: String, Codable {
    case task
    case event
    case reminder
    case focus
    case breakTime
}

enum FlexLevel: String, Codable {
    case fixed      // never move (meetings, class)
    case semiFlex   // can shift, but try to keep near original
    case flexible   // safe to shift
}

struct ScheduleBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var kind: BlockKind
    var flex: FlexLevel

    // Stored as minutes from midnight for easy math
    var startMin: Int
    var durationMin: Int

    // Optional: buffer before/after used by resolver
    var bufferBeforeMin: Int
    var bufferAfterMin: Int

    // Optional: learned label key (can be derived from title)
    var learnKey: String?

    init(
        id: UUID = UUID(),
        title: String,
        kind: BlockKind = .task,
        flex: FlexLevel = .flexible,
        startMin: Int,
        durationMin: Int,
        bufferBeforeMin: Int = 0,
        bufferAfterMin: Int = 0,
        learnKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.flex = flex
        self.startMin = startMin
        self.durationMin = durationMin
        self.bufferBeforeMin = bufferBeforeMin
        self.bufferAfterMin = bufferAfterMin
        self.learnKey = learnKey
    }

    var endMin: Int { startMin + durationMin }

    func overlaps(with other: ScheduleBlock) -> Bool {
        // allow touching edges (end == start) = not overlap
        return !(self.endMin <= other.startMin || other.endMin <= self.startMin)
    }
}

extension String {
    /// Simple normalization for learning keys (no LLM)
    func normalizedLearnKey() -> String {
        let lower = self.lowercased()
        let allowed = lower.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let squashed = allowed.split(separator: " ").joined(separator: " ")
        return squashed
    }
}

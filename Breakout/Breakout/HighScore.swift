//
//  HighScore.swift
//  Breakout
//
//  Created by ana videnovic on 1/25/18.
//  Copyright © 2018 ana videnovic. All rights reserved.
//

import Foundation
import CoreData

class HighScore: NSManagedObject {

    static func isNewHigh(score: Int, forBallCount numberOfBalls: Int, in context: NSManagedObjectContext) -> Bool {

        let request: NSFetchRequest<HighScore> = HighScore.fetchRequest()
        request.predicate = NSPredicate(format: "numberOfBalls = %@", numberOfBalls as NSNumber)

        if let highScoresCount = try? context.count(for: request),
            highScoresCount < Constants.maximumNumberOfHighScores {
            return true
        }

        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        request.fetchLimit = 1

        do {
            let match = try context.fetch(request)
            assert(match.count == 1, "HighScore -- error when trying to get just the bottom high score.")
            if match[0].score > score {
                context.delete(match[0])
                return true
            }
        } catch {
            print(error)
        }

        return false
    }

    static func updateHighScores(with score: Int, ofUserNamed userName: String, forBallCount numberOfBalls: Int, in context: NSManagedObjectContext) {
        let highScore = HighScore(context: context)
        highScore.score = Int64(score)
        highScore.numberOfBalls = Int16(numberOfBalls)
        highScore.name = userName
    }
}

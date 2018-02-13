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
                return true
            }
        } catch {
            print(error)
        }

        return false
    }

    static func updateHighScores(with score: Int, ofUserNamed userName: String, forBallCount numberOfBalls: Int, in context: NSManagedObjectContext) {

        // if current number of highscores >= maximal delete the worst scores to make room

        let request: NSFetchRequest<NSFetchRequestResult> = HighScore.fetchRequest()
        request.predicate = NSPredicate(format: "numberOfBalls = %@", numberOfBalls as NSNumber)
        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]

        if let highScoresCount = try? context.count(for: request), highScoresCount >= Constants.maximumNumberOfHighScores {

            request.fetchLimit = (highScoresCount - Constants.maximumNumberOfHighScores) + 1
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

            do {
                try context.execute(deleteRequest)
            } catch {
                print(error)
            }
        }

        // then save the new high score

        let highScore = HighScore(context: context)
        highScore.score = Int64(score)
        highScore.numberOfBalls = Int16(numberOfBalls)
        highScore.name = userName
    }
}

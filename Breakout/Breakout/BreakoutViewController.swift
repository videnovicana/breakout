//
//  BreakoutViewController.swift
//  Breakout
//
//  Created by ana videnovic on 10/20/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit
import CoreData

class BreakoutViewController: UIViewController {
    
    // MARK: - view
    private var gameView: BreakoutView! {
        didSet {
            gameView.addGestureRecognizer(UITapGestureRecognizer(target: gameView, action: #selector(BreakoutView.pushBalls(byReactingTo:))))
            gameView.addGestureRecognizer(UIPanGestureRecognizer(target: gameView, action: #selector(BreakoutView.movePaddle(byReactingTo:))))
        }
    }
    
    // MARK: - view animating tools
    private lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
    private var ballBehavior = BallBehavior()

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeIfNeeded()
    }

    // MARK: - view life cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animator.addBehavior(ballBehavior)
        refreshSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        animator.removeBehavior(ballBehavior)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if gameView != nil, gameView.frame.size != view.bounds.size {
            gameView.frame = self.view.bounds
            gameView.redrawGameViewUponRotation()
        }
    }

    private func initializeIfNeeded() {
        if gameView == nil {
            gameView = BreakoutView(
                frame: CGRect(center: view.bounds.mid, size: view.bounds.size),
                ballBehavior: ballBehavior,
                ballCount: UserDefaultsManager.numberOfBalls ?? Constants.defautlNumberOfBalls,
                brickCount: UserDefaultsManager.numberOfBricks ?? Constants.defaultNumberOfBricks,
                ballBounciness: CGFloat(UserDefaultsManager.ballBounciness ?? 1.0),
                useRealGravity: UserDefaultsManager.realGravityIsOn ?? false
            )
            view.addSubview(gameView)

            gameView.highScoresDelegate = self
        }
    }

    private func refreshSettings() {
        gameView.set(
            ballCount: UserDefaultsManager.numberOfBalls ?? Constants.defautlNumberOfBalls,
            brickCount: UserDefaultsManager.numberOfBricks ?? Constants.defaultNumberOfBricks,
            bounciness: CGFloat(UserDefaultsManager.ballBounciness ?? 1.0),
            realGravityIsOn: UserDefaultsManager.realGravityIsOn ?? false
        )
    }

    // MARK: - saving to model
    private let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
}

protocol HighScoresDelegate : class {
    func checkIfNewHigh(score: Int, forBallCount numberOfBalls: Int) -> Bool
    func updateHighScores(with score: Int, forBallCount numberOfBalls: Int)
}

extension BreakoutViewController : HighScoresDelegate {

    func checkIfNewHigh(score: Int, forBallCount numberOfBalls: Int) -> Bool {
        if let context = container?.viewContext {
            return HighScore.isNewHigh(score: score, forBallCount: numberOfBalls, in: context)
        }
        print("missing context!")
        return false
    }

    func updateHighScores(with score: Int, forBallCount numberOfBalls: Int) {

        let alert = UIAlertController(title: "New high score!", message: "Time: \(score)", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Your Name"
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default)
            { [unowned self] action in

                let playerName: String
                if let name = alert.textFields?.first?.text, !name.isEmpty {
                    playerName = name
                } else {
                    playerName = Constants.defaultPlayerName
                }

                self.container?.performBackgroundTask { [weak self] context in
                    HighScore.updateHighScores(with: score, ofUserNamed: playerName, forBallCount: numberOfBalls, in: context)
                    try? context.save()
                    self?.printDatabase()
                }
                self.gameView.setUpNewGameView()
            }
        )

        present(alert, animated: true, completion: nil)
    }

    private func printDatabase() {
        if let context = container?.viewContext {
            let request: NSFetchRequest<HighScore> = HighScore.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "numberOfBalls", ascending: true), NSSortDescriptor(key: "score", ascending: true)]

            let allRecords = try? context.fetch(request)

            for record in allRecords ?? [] {
                print("\(record.name ?? "NoNameSaved" ), time: \(record.score)s, \(record.numberOfBalls)-ball-game")
            }
        }
    }
}

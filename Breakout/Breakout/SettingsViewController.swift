//
//  SettingsViewController.swift
//  Breakout
//
//  Created by ana videnovic on 10/28/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var numberOfBallsControl: UISegmentedControl!
    //@IBOutlet private weak var numberOfBricksStepper: UIStepper!
    @IBOutlet private weak var ballBouncinessSlider: UISlider!
    @IBOutlet private weak var gravityPullSwitch: UISwitch!
    
    @IBOutlet private weak var numberOfBricksLabel: UILabel! {
        didSet {
            numberOfBricksLabel.text = String(UserDefaultsManager.numberOfBricks ?? Constants.defaultNumberOfBricks)
        }
    }
    
    @IBAction func updateNumberOfBalls(_ sender: UISegmentedControl) {
        UserDefaultsManager.numberOfBalls = sender.selectedSegmentIndex + 1
    }
    
    @IBAction func updateNumberOfBricks(_ sender: UIStepper) {
        numberOfBricksLabel?.text = String(Int(sender.value))
        UserDefaultsManager.numberOfBricks = Int(sender.value)
    }
    
    @IBAction func updateBounciness(_ sender: UISlider) {
        UserDefaultsManager.ballBounciness = sender.value
    }
    
    @IBAction func toggledGravitySwitch(_ sender: UISwitch) {
        UserDefaultsManager.realGravityIsOn = sender.isOn
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSavedSettings()
    }

    private func showSavedSettings() {
        numberOfBallsControl?.selectedSegmentIndex = (UserDefaultsManager.numberOfBalls ?? 1) - 1
        ballBouncinessSlider?.value = UserDefaultsManager.ballBounciness ?? 1.0
        gravityPullSwitch?.isOn = UserDefaultsManager.realGravityIsOn ?? false
    }
}

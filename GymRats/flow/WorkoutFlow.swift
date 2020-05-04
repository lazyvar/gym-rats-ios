//
//  WorkoutFlow.swift
//  GymRats
//
//  Created by mack on 3/16/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import UIKit

enum WorkoutFlow {
  private static let createWorkoutDelegate = CreateWorkoutDelegateObject()
  private static let generator = UIImpactFeedbackGenerator(style: .heavy)

  static func logWorkout() {
    generator.impactOccurred()

    let logWorkoutModal = LogWorkoutModalViewController() { source in
      let createWorkoutViewController = CreateWorkoutViewController(source: source)
      createWorkoutViewController.delegate = createWorkoutDelegate
      
      UIViewController.topmost().present(createWorkoutViewController.inNav(), animated: true, completion: nil)
    }
    
    UIViewController.topmost().presentPanModal(logWorkoutModal)
  }
}

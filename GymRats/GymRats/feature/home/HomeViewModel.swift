//
//  HomeViewModel.swift
//  GymRats
//
//  Created by mack on 3/10/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel: ViewModel {
  
  private let disposeBag = DisposeBag()
  
  struct Input {
    let viewDidLoad = PublishSubject<Void>()
  }
  
  struct Output {
    let error = PublishSubject<Error>()
    let installScreen = PublishSubject<Screen>()
  }
  
  let input = Input()
  let output = Output()
  
  init() {
    let challenges = input.viewDidLoad
      .flatMap { Challenge.all.fetch() }
      .observeOn(MainScheduler.instance)
      .share()
    
    challenges
      .compactMap { $0.error }
      .bind(to: output.error)
      .disposed(by: disposeBag)
    
    challenges
      .compactMap { $0.object }
      .map { challenges -> Screen in
        guard challenges.isNotEmpty else { return .noChallenges }
        
        let challengeId = UserDefaults.standard.integer(forKey: "last_opened_challenge")
        let challenge = challenges.first { $0.id == challengeId } ?? challenges.first
        
        return .activeChallenge(challenge!)
      }
      .do(onNext: { _ in
        if let notification = GymRatsApp.coordinator.coldStartNotification {
          GymRatsApp.coordinator.handleNotification(userInfo: notification)
          GymRatsApp.coordinator.coldStartNotification = nil
        }
      })
      .bind(to: output.installScreen)
      .disposed(by: disposeBag)
  }
}

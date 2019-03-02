//
//  ChallengeInfoViewController.swift
//  GymRats
//
//  Created by Mack Hasz on 2/11/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import UIKit
import MMDrawerController
import YogaKit

class ChallengeInfoViewController: UITableViewController {
    
    let challenge: Challenge
    let workouts: [Workout]
    let members: [User]
    
    init(challenge: Challenge, workouts: [Workout], users: [User]) {
        self.workouts = workouts
        self.members = users
        self.challenge = challenge
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "UserWorkoutTableViewCell", bundle: nil), forCellReuseIdentifier: "ChallengeUserCell")
        
        let containerView = UIView()
        
        containerView.configureLayout { layout in
            layout.isEnabled = true
            layout.flexDirection = .column
            layout.justifyContent = .flexStart
            layout.alignContent = .flexStart
            layout.width = 280
            layout.paddingTop = 10
            layout.padding = 10
        }

        let imageView = UserImageView()
        imageView.load(avatarInfo: challenge)
        
        imageView.configureLayout { layout in
            layout.isEnabled = true
            layout.width = 80
            layout.height = 80
            layout.margin = 5
        }
        
        let imageViewContainer = UIView()
        
        imageViewContainer.configureLayout { layout in
            layout.isEnabled = true
            layout.flexDirection = .row
            layout.alignContent = .center
            layout.justifyContent = .center
        }
        
        let challengeNameLabel = UILabel()
        challengeNameLabel.font = .body
        challengeNameLabel.textAlignment = .center
        challengeNameLabel.textColor = .black
        challengeNameLabel.text = challenge.name
        
        challengeNameLabel.configureLayout { layout in
            layout.isEnabled = true
            layout.marginTop = 5
        }

        let codeLabel = UILabel()
        codeLabel.font = .details
        codeLabel.textAlignment = .center
        codeLabel.text = "Join code: \(challenge.code)"
        
        codeLabel.configureLayout { layout in
            layout.isEnabled = true
            layout.marginTop = 5
        }
        
        imageViewContainer.addSubview(imageView)
        
        imageViewContainer.yoga.applyLayout(preservingOrigin: true)

        let difference = Date().getInterval(toDate: challenge.endDate, component: .day)
        
        let daysLeft = UILabel()
        daysLeft.font = .details
        daysLeft.textAlignment = .center
        
        if difference == 0 {
            daysLeft.text =  "Last day (\(challenge.endDate.toFormat("MMM d")))"
        } else {
            daysLeft.text =  "\(difference) days remaining (\(challenge.endDate.toFormat("MMM d")))"
        }
        
        daysLeft.configureLayout { layout in
            layout.isEnabled = true
            layout.marginTop = 5
        }

        containerView.addSubview(imageViewContainer)
        containerView.addSubview(challengeNameLabel)
        containerView.addSubview(codeLabel)
        containerView.addSubview(daysLeft)

        containerView.yoga.applyLayout(preservingOrigin: true, dimensionFlexibility: .flexibleHeight)

        tableView.tableHeaderView = containerView
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Top Rats"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeUserCell") as! UserWorkoutTableViewCell
        let usersRanked = members.map { user in
            return (user: user, workouts: workouts.filter({ $0.gymRatsUserId == user.id }))
        }.sorted { a, b in
            return a.workouts.count > b.workouts.count
        }
        
        let user = usersRanked[indexPath.row].user
        let numberOfWorkouts = usersRanked[indexPath.row].workouts.count
        
        cell.configure(for: user, withNumberOfWorkouts: numberOfWorkouts)
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let usersRanked = members.map { user in
            return (user: user, workouts: workouts.filter({ $0.gymRatsUserId == user.id }))
        }.sorted { a, b in
            return a.workouts.count > b.workouts.count
        }
        
        let user = usersRanked[indexPath.row].user
        
        GymRatsApp.coordinator.drawer.closeDrawer(animated: true) { _ in
            let center = GymRatsApp.coordinator.drawer.centerViewController
            let profile = ProfileViewController(user: user, challenge: self.challenge)
            
            if let center = center as? GRNavigationController {
                center.pushViewController(profile, animated: true)
            }
        }
    }

}

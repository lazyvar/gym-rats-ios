//
//  WorkoutViewController.swift
//  GymRats
//
//  Created by Mack Hasz on 2/5/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import UIKit
import RxSwift
import YogaKit
import MapKit

class WorkoutViewController: UIViewController {

    let disposeBag = DisposeBag()
    let user: User
    let workout: Workout
    
    let refresher = UIRefreshControl()
    
    let userImageView: UserImageView = UserImageView()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        
        return label
    }()
    
    init(user: User, workout: Workout) {
        self.user = user
        self.workout = workout
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()
        
        let containerView = UIView()
        containerView.frame = view.frame
        containerView.backgroundColor = .white
        
        let headerView = UIView()
        
        let userImageView = UserImageView()
        userImageView.load(avatarInfo: user)
        
        let usernameLabel: UILabel = UILabel()
        usernameLabel.font = .body
        usernameLabel.text = user.fullName

        let timeLabel: UILabel = UILabel()
        timeLabel.font = .details
        timeLabel.text = workout.date.challengeTime
        timeLabel.textAlignment = .right
        
        headerView.configureLayout { layout in
            layout.isEnabled = true
            layout.flexDirection = .row
            layout.justifyContent = .flexStart
            layout.padding = 15
        }
        
        userImageView.configureLayout { layout in
            layout.isEnabled = true
            layout.width = 32
            layout.height = 32
        }
        
        usernameLabel.configureLayout { layout in
            layout.isEnabled = true
            layout.marginLeft = 10
        }

        timeLabel.configureLayout { layout in
            layout.isEnabled = true
            layout.flexGrow = 1
        }

        headerView.addSubview(userImageView)
        headerView.addSubview(usernameLabel)
        headerView.addSubview(timeLabel)

        headerView.yoga.applyLayout(preservingOrigin: true)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(transitionToProfile))
        tap.numberOfTapsRequired = 1
        
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(tap)
        
        containerView.configureLayout { layout in
            layout.isEnabled = true
            layout.flexDirection = .column
            layout.justifyContent = .flexStart
        }
        
        containerView.addSubview(headerView)

        if let pictureUrl = workout.pictureUrl, let url = URL(string: pictureUrl) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.backgroundColor = .whiteSmoke

            imageView.configureLayout { layout in
                layout.isEnabled = true
                layout.flexGrow = 1
                layout.width = YGValue(self.view.frame.width)
                layout.height = YGValue(self.view.frame.width)
            }

            imageView.kf.setImage(with: url)

            containerView.addSubview(imageView)
        }
        
        if let place = workout.place {
            let mapView = MKMapView()
            let initialLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let coordinateRegion = MKCoordinateRegion (
                center: initialLocation.coordinate,
                latitudinalMeters: 500, longitudinalMeters: 500
            )
            let annotation = PlaceAnnotation (
                title: place.name,
                coordinate: CLLocationCoordinate2D (
                    latitude: place.latitude,
                    longitude: place.longitude
                )
            )

            mapView.setRegion(coordinateRegion, animated: true)
            mapView.mapType = .standard
            mapView.isUserInteractionEnabled = false
            mapView.addAnnotation(annotation)

            mapView.configureLayout { layout in
                layout.isEnabled = true
                layout.width = YGValue(self.view.frame.width)
                layout.height = 115
                layout.marginTop = 2
            }
            
            containerView.addSubview(mapView)
        }
        
        let titleLabel: UILabel = UILabel()
        titleLabel.font = .body
        titleLabel.text = workout.title
        
        titleLabel.configureLayout { layout in
            layout.isEnabled = true
            layout.margin = 15
        }
        
        containerView.addSubview(titleLabel)
        
        if let description = workout.description {
            let descriptionLabel = UILabel()
            descriptionLabel.text = description
            descriptionLabel.numberOfLines = 0
            descriptionLabel.font = .body
            descriptionLabel.configureLayout { layout in
                layout.isEnabled = true
                layout.margin = 15
                layout.marginTop = 0
            }
            
            containerView.addSubview(descriptionLabel)
        }

        containerView.yoga.applyLayout(preservingOrigin: true, dimensionFlexibility: .flexibleHeight)
        containerView.makeScrolly(in: view)
    }
    
    @objc func transitionToProfile() {
        self.push(ProfileViewController(user: user))
    }
    
}

class PlaceAnnotation: NSObject, MKAnnotation {

    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return nil
    }
}

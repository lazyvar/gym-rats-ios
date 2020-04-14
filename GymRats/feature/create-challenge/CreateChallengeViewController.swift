//
//  CreateChallengeViewController.swift
//  GymRats
//
//  Created by mack on 4/13/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import UIKit
import RxSwift
import Eureka
import SwiftDate

class CreateChallengeViewController: GRFormViewController {
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Create challenge"
    
    tableView.backgroundColor = .background
    tableView.separatorStyle = .none
    
    form = form
      +++ mainSection
        <<< nameRow
        <<< descriptionRow
        <<< startDateRow
        <<< durationRow
        <<< endDateRow
        <<< scoreRow
  }
    
  @objc private func nextTapped() {
    guard form.validate().count == 0 else { return }
    
    
  }
    
  // MARK: Eurekah

  private lazy var mainSection: Section = {
    return Section() { section in
      section.footer = self.sectionFooter
    }
  }()
  
  private lazy var nameRow: TextFieldRow = {
    return TextFieldRow() { textRow in
      textRow.placeholder = "Group name"
      textRow.tag = "name"
      textRow.icon = .people
      textRow.add(rule: RuleRequired(msg: "Name is required."))
    }
    .onRowValidationChanged(self.handleRowValidationChange)
  }()

  private lazy var descriptionRow: TextViewRow = {
    return TextViewRow() { textRow in
      textRow.placeholder = "Descripton (optional)"
      textRow.tag = "descripton"
      textRow.icon = .clipboard
    }
  }()

  private lazy var startDateRow: PickDateRow = {
    return PickDateRow() { textRow in
      textRow.placeholder = "Start date"
      textRow.tag = "start_date"
      textRow.icon = .cal
      textRow.add(rule: RuleRequired(msg: "Start date is required."))
      textRow.value = Date()
      textRow.startDate = Date()
    }
  }()

  private lazy var durationRow: IntegerPickerRow = {
    return IntegerPickerRow() { textRow in
      textRow.placeholder = "Duration"
      textRow.icon = .clock
      textRow.value = 30
      textRow.numberOfRows = 1000.years.in(.day) ?? 0
    }
  }()

  private lazy var endDateRow: PickDateRow = {
    return PickDateRow() { textRow in
      textRow.placeholder = "End date"
      textRow.tag = "end_date"
      textRow.icon = .cal
      textRow.add(rule: RuleRequired(msg: "End date is required."))
      textRow.startDate = Date()
      textRow.value = Date() + 30.days
      textRow.endDate = Date() + 1000.years
    }
  }()

  private lazy var scoreRow: IntegerPickerRow = {
    return IntegerPickerRow() { textRow in
      textRow.placeholder = "Score by"
      textRow.tag = "score_by"
      textRow.add(rule: RuleRequired(msg: "Score is required."))
      textRow.icon = .star
      textRow.value = 0
      textRow.numberOfRows = ScoreBy.allCases.count
      textRow.displayInt = { ScoreBy.init(rawValue: $0)?.display ?? "" }
    }
  }()

  private lazy var sectionFooter: HeaderFooterView<UIView> = {
    let footerBuilder = { () -> UIView in
      let container = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 70))
      let goButton = PrimaryButton().apply {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("Next", for: .normal)
      }

      container.addSubview(goButton)

      goButton.addTarget(self, action: #selector(self.nextTapped), for: .touchUpInside)
      goButton.constrainWidth(250)
      goButton.constrainHeight(48)
      goButton.horizontallyCenter(in: container)
      goButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 10).isActive = true

      return container
    }
    
    var footer = HeaderFooterView<UIView>(.callback(footerBuilder))
    footer.height = { 100 }
    
    return footer
  }()
  
  private func handleRowValidationChange(cell: UITableViewCell, row: TextFieldRow) {
    guard let textRowNumber = row.indexPath?.row, var section = row.section else { return }
    
    let validationLabelRowNumber = textRowNumber + 1
    
    while validationLabelRowNumber < section.count && section[validationLabelRowNumber] is ErrorLabelRow {
      section.remove(at: validationLabelRowNumber)
    }
    
    if row.isValid { return }
    
    for (index, validationMessage) in row.validationErrors.map({ $0.msg }).enumerated() {
      let labelRow = ErrorLabelRow()
        .cellSetup { cell, _ in
          cell.errorLabel.text = validationMessage
        }
      
      section.insert(labelRow, at: validationLabelRowNumber + index)
    }
  }
}

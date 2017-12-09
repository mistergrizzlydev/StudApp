//
//  CourseController.swift
//  StudApp
//
//  Created by Steffen Ryll on 09.12.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import StudKit

final class CourseController: UITableViewController, Routable {
    private var viewModel: CourseViewModel!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = viewModel.course.title

        initUserInterface()
    }

    func prepareDependencies(for route: Routes) {
        guard case let .course(course) = route else { fatalError() }

        viewModel = CourseViewModel(course: course)
    }

    // MARK: - User Interface

    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var courseNumberCell: UITableViewCell!

    @IBOutlet weak var locationCell: UITableViewCell!

    @IBOutlet weak var summaryCell: UITableViewCell!

    @IBOutlet weak var summaryLabel: UILabel!

    private func initUserInterface() {
        subtitleLabel.text = viewModel.course.subtitle

        courseNumberCell.textLabel?.text = "Course Number".localized
        courseNumberCell.detailTextLabel?.text = viewModel.course.number

        locationCell.textLabel?.text = "Location".localized
        locationCell.detailTextLabel?.text = viewModel.course.location

        summaryLabel.text = viewModel.course.summary
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

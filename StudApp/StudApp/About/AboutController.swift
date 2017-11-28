//
//  AboutController.swift
//  StudApp
//
//  Created by Steffen Ryll on 28.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import StudKit

final class AboutController: UITableViewController, Routable {
    private var viewModel: AboutViewModel!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = AboutViewModel()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: thanksCellIdentifier)
    }

    // MARK: - User Intercation

    @IBAction
    func doneButtonTapped(_: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table View Data Source

    private let thanksCellIdentifier = "ThanksCell"

    private let thanksSectionIndex = 2

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case thanksSectionIndex:
            return viewModel.numberOfRows
        default:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case thanksSectionIndex:
            let cell = tableView.dequeueReusableCell(withIdentifier: thanksCellIdentifier, for: indexPath)
            let thanks = viewModel[rowAt: indexPath.row]
            cell.textLabel?.text = thanks.title
            cell.detailTextLabel?.text = thanks.description
            return cell
        default:
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    // MARK: Table View Delegate

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        // Needs to be overridden in order to avoid index-out-of-range-exceptions caused by static cells.
        switch indexPath.section {
        case thanksSectionIndex:
            return super.tableView(tableView, indentationLevelForRowAt: IndexPath(row: 0, section: indexPath.section))
        default:
            return super.tableView(tableView, indentationLevelForRowAt: indexPath)
        }
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        // Needs to be overriden in order to activate dynamic row sizing. This value is not set in interface builder because it
        // would reset the rows' sizes to the default size in preview.
        return UITableViewAutomaticDimension
    }
}

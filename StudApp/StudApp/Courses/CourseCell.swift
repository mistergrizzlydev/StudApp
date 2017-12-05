//
//  CourseCell.swift
//  StudApp
//
//  Created by Steffen Ryll on 23.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import StudKit

final class CourseCell: UITableViewCell {
    // MARK: - Life Cycle

    var course: Course! {
        didSet {
            colorView.backgroundColor = UI.Colors.pickerColors[course.state.colorId] ?? UI.Colors.studBlue
            titleLabel.text = course.title
            lecturersLabel.text = course.lecturers
                .map { $0.nameComponents.formatted() }
                .joined(separator: ", ")
        }
    }

    // MARK: - User Interface

    @IBOutlet weak var colorView: UIView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var lecturersGlyph: UIImageView!

    @IBOutlet weak var lecturersLabel: UILabel!

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        colorView.backgroundColor = UI.Colors.pickerColors[course.state.colorId] ?? UI.Colors.studBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        colorView.backgroundColor = UI.Colors.pickerColors[course.state.colorId] ?? UI.Colors.studBlue
    }
}

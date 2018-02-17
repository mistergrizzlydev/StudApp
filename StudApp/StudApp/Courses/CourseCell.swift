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
            colorView.backgroundColor = course.state.color
            titleLabel.text = course.title
            lecturersLabel.text = course.lecturers
                .map { $0.nameComponents.formatted() }
                .sorted()
                .joined(separator: ", ")
        }
    }

    var presentColorPicker: ((CourseCell) -> Void)?

    // MARK: - User Interface

    @IBOutlet var colorView: UIView!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var lecturersGlyph: UIImageView!

    @IBOutlet var lecturersLabel: UILabel!

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        colorView.backgroundColor = course.state.color
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        colorView.backgroundColor = course.state.color
    }

    // MARK: - User Interaction

    @objc
    func color(_: Any?) {
        presentColorPicker?(self)
    }
}

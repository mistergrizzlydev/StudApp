//
//  StudApp—Stud.IP to Go
//  Copyright © 2018, Steffen Ryll
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/.
//

import StudKit

final class ColorCell: UICollectionViewCell {

    // MARK: - Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = false

        isAccessibilityElement = true
        accessibilityTraits.insert(.button)

        guard #available(iOS 11.0, *) else { return }
        glowView.accessibilityIgnoresInvertColors = true
    }

    // MARK: - User Interface

    @IBOutlet var glowView: GlowView!

    var color: UIColor? {
        didSet { glowView.color = color }
    }

    var title: String? {
        didSet { accessibilityLabel = title }
    }

    override var isHighlighted: Bool {
        didSet { glowView.isHighlighted = isHighlighted }
    }
}

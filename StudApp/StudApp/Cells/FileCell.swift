//
//  FileCell.swift
//  StudApp
//
//  Created by Steffen Ryll on 23.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import StudKit

final class FileCell: UITableViewCell {
    // MARK: - Life Cycle

    var file: File! {
        didSet {
            accessoryType = file.isFolder ? .disclosureIndicator : .none

            iconView.image = nil
            file.documentController { self.iconView?.image = $0.icons.first }

            titleLabel.text = file.title

            modificationDateLabel?.text = file.modifiedAt.formattedAsShortDifferenceFromNow
            sizeLabel.text = file.size.formattedAsByteCount
            downloadCountLabel.text = "%dx".localized(file.downloadCount)
            userGlyph.isHidden = file.owner == nil
            userLabel.text = file.owner?.nameComponents.formatted()

            activityIndicator?.isHidden = !file.state.isDownloading
            downloadGlyph?.isHidden = file.state.isMostRecentVersionDownloaded || file.state.isDownloading
        }
    }

    // MARK: - User Interface

    @IBOutlet weak var iconView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var modificationDateLabel: UILabel!

    @IBOutlet weak var sizeLabel: UILabel!

    @IBOutlet weak var downloadCountLabel: UILabel!

    @IBOutlet weak var userGlyph: UIImageView!

    @IBOutlet weak var userLabel: UILabel!

    @IBOutlet weak var activityIndicator: StudIpActivityIndicatorView?

    @IBOutlet weak var downloadGlyph: UIImageView?

    // MARK: - User Interaction

    @objc
    func share(_: Any?) {
        file.documentController { $0.presentOptionsMenu(from: self.frame, in: self, animated: true) }
    }

    @objc
    func remove(_: Any?) {
        try? file.removeDownload()
    }
}

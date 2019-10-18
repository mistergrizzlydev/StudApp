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
import StudKitUI

final class FileCell: UITableViewCell {
    static let estimatedHeight: CGFloat = 72

    private let fileIconService = ServiceContainer.default[FileIconService.self]
    private let reachabilityService = ServiceContainer.default[ReachabilityService.self]

    // MARK: - Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityDidChange(notification:)),
                                               name: .reachabilityDidChange, object: nil)

        unreadIndicatorView.accessibilityIgnoresInvertColors = true
        iconView.accessibilityIgnoresInvertColors = true
    }

    var file: File! {
        didSet {
            let modifiedAt = file.modifiedAt.formattedAsShortDifferenceFromNow
            let userFullname = file.owner?.nameComponents.formatted()
            let size = file.size.formattedAsByteCount
            let host = file.externalUrl?.host

            accessoryType = file.isFolder || !file.isLocationSecure ? .disclosureIndicator : .none

            iconView.image = nil
            fileIconService.icon(for: file) { self.iconView?.image = $0 }

            unreadIndicatorContainerView.isHidden = !file.isNew || file.isFolder
            unreadIndicatorView.backgroundColor = file.course.color

            titleLabel.text = file.title
            titleLabel.numberOfLines = Targets.current.preferredContentSizeCategory.isAccessibilityCategory ? 3 : 1

            modifiedAtLabel?.text = modifiedAt
            userLabel.text = userFullname
            sizeLabel.text = size
            hostLabel.text = host
            downloadCountLabel.text = Strings.Formats.numberOfTimes.localized(file.downloadCount)
            childCountLabel?.text = Strings.Formats.numberOfItems.localized(file.children.count)

            activityIndicator?.isHidden = !file.state.isDownloading
            downloadGlyph?.isHidden = !file.isDownloadable || !file.isLocationSecure

            updateSubtitleHiddenStates()
            updateReachabilityIndicator()

            let isNewState = file.isNew ? Strings.States.new.localized : nil
            let modifiedBy = userFullname != nil ? Strings.Formats.byEntity.localized(userFullname ?? "") : nil
            let modifiedAtBy = [Strings.States.modified.localized, modifiedAt, modifiedBy].compactMap { $0 }.joined(separator: " ")
            let folderOrDocument = file.isFolder ? Strings.Terms.folder.localized : Strings.Terms.document.localized
            let sizeOrItemCount = file.isFolder ? Strings.Formats.numberOfItems.localized(file.children.count) : size
            let hostedBy = file.location == .external || file.location == .website
                ? Strings.Formats.hostedBy.localized(host ?? "") : nil

            accessibilityLabel = [
                isNewState, folderOrDocument, file.title, modifiedAtBy, sizeOrItemCount, hostedBy,
            ].compactMap { $0 }.joined(separator: ", ")

            let shareAction = UIAccessibilityCustomAction(name: Strings.Actions.share.localized, target: self,
                                                          selector: #selector(share(_:)))
            let removeAction = UIAccessibilityCustomAction(name: Strings.Actions.remove.localized, target: self,
                                                           selector: #selector(remove(_:)))
            let markAction = file.isNew
                ? UIAccessibilityCustomAction(name: Strings.Actions.markAsSeen.localized, target: self,
                                              selector: #selector(markAsSeen(_:)))
                : UIAccessibilityCustomAction(name: Strings.Actions.markAsSeen.localized, target: self,
                                              selector: #selector(markAsNew(_:)))

            accessibilityCustomActions = [
                file.state.isDownloaded ? shareAction : nil,
                file.state.isDownloaded ? removeAction : nil,
                !file.isFolder ? markAction : nil,
            ].compactMap { $0 }
        }
    }

    // MARK: - User Interface

    override var frame: CGRect {
        didSet { updateSubtitleHiddenStates() }
    }

    @IBOutlet var iconView: UIImageView!

    @IBOutlet var unreadIndicatorContainerView: UIView!

    @IBOutlet var unreadIndicatorView: UIView!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var modifiedAtContainer: UIStackView!

    @IBOutlet var modifiedAtLabel: UILabel!

    @IBOutlet var userContainer: UIStackView!

    @IBOutlet var userLabel: UILabel!

    @IBOutlet var sizeContainer: UIStackView!

    @IBOutlet var sizeLabel: UILabel!

    @IBOutlet var hostContainer: UIStackView!

    @IBOutlet var hostLabel: UILabel!

    @IBOutlet var downloadCountContainer: UIStackView!

    @IBOutlet var downloadCountLabel: UILabel!

    @IBOutlet var childCountContainer: UIStackView?

    @IBOutlet var childCountLabel: UILabel?

    @IBOutlet var activityIndicator: StudIpActivityIndicator?

    @IBOutlet var downloadGlyph: UIImageView?

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        unreadIndicatorView.backgroundColor = file.course.color
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        unreadIndicatorView.backgroundColor = file.course.color
    }

    private func updateSubtitleHiddenStates() {
        guard let file = file else { return }
        sizeContainer.isHidden = file.size <= 0
        hostContainer.isHidden = file.location != .external && file.location != .website
        downloadCountContainer.isHidden = file.downloadCount <= 0 || frame.width < 512
        childCountContainer?.isHidden = !file.isFolder || file.state.childFilesUpdatedAt == nil
        userContainer.isHidden = file.owner == nil || frame.width < 512
    }

    private func updateReachabilityIndicator() {
        UIView.animate(withDuration: UI.defaultAnimationDuration) {
            self.contentView.alpha = self.file.isAvailable ? 1 : 0.5
        }
    }

    // MARK: - Notifications

    @objc
    private func reachabilityDidChange(notification _: Notification) {
        updateReachabilityIndicator()
    }

    // MARK: - User Interaction

    @objc
    func share(_: Any?) -> Bool {
        let controller = UIDocumentInteractionController(url: file.localUrl(in: .fileProvider))
        controller.name = file.title
        controller.presentOptionsMenu(from: frame, in: self, animated: true)
        return true
    }

    @objc
    func remove(_: Any?) -> Bool {
        do {
            try file.removeDownload()
            return true
        } catch {
            return false
        }
    }

    @objc
    func markAsNew(_: Any?) {
        file.isNew = true
    }

    @objc
    func markAsSeen(_: Any?) {
        file.isNew = false
    }

    // MARK: - Accessibility

    override var accessibilityValue: String? {
        get {
            guard !file.isFolder else { return nil }
            guard file.isAvailable else { return Strings.States.unavailable.localized }
            guard !file.state.isDownloading else { return Strings.States.downloading.localized }
            guard file.state.isDownloaded else { return Strings.States.notDownloaded.localized }
            return Strings.States.downloaded.localized
        }
        set {}
    }
}

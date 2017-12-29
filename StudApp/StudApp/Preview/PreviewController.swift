//
//  PreviewController.swift
//  StudApp
//
//  Created by Steffen Ryll on 02.12.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import QuickLook
import StudKit

final class PreviewController: QLPreviewController, Routable {
    private var coreDataService = ServiceContainer.default[CoreDataService.self]
    private var historyService = ServiceContainer.default[HistoryService.self]

    // MARK: - Life Cycle

    private var file: File!

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self

        file.download { result in
            guard result.isSuccess else {
                let alert = UIAlertController(title: result.error?.localizedDescription, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay".localized, style: .default, handler: nil))
                return self.present(alert, animated: true, completion: nil)
            }

            self.refreshCurrentPreviewItem()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        userActivity = file.userActivity
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        try? historyService.mergeHistory(into: coreDataService.viewContext)
        try? historyService.deleteHistory(mergedInto: Targets.iOSTargets, in: coreDataService.viewContext)
    }

    func prepareDependencies(for route: Routes) {
        guard case let .preview(file, delegate) = route else { fatalError() }
        self.file = file
        self.delegate = delegate
    }

    // MARK: - Supporting User Activities

    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.objectIdentifier = file.objectIdentifier
    }

    // MARK: - Utilities

    static func downloadOrPreview(_ file: File, in controller: UIViewController & QLPreviewControllerDelegate) {
        guard file.state.isMostRecentVersionDownloaded else {
            file.download { result in
                guard result.isFailure else { return }

                let error = result.error?.localizedDescription ?? "Something went wrong downloading this document".localized
                let alert = UIAlertController(title: error, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay".localized, style: .default, handler: nil))
                controller.present(alert, animated: true, completion: nil)
            }
            return
        }

        let previewController = PreviewController()
        previewController.prepareDependencies(for: .preview(file, controller))
        controller.present(previewController, animated: true, completion: nil)
    }
}

// MARK: - QuickLook Data Source

extension PreviewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
        return file
    }
}

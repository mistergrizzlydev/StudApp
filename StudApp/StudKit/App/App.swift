//
//  App.swift
//  StudKit
//
//  Created by Steffen Ryll on 28.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

/// Provides constants regarding app information.
public enum App {

    // MARK: - Urls

    public enum Urls {

        // MARK: Website

        public static let website = URL(string: "https://studapp.stoeffn.de/")!

        public static let help = URL(string: "https://studapp.stoeffn.de/help")!

        public static let privacyPolicy = URL(string: "https://studapp.stoeffn.de/privacy")!

        public static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

        // MARK: iTunes and App Store

        /// App Store URL.
        public static let appStore = URL(string: "https://itunes.apple.com/de/app/\(App.id)")!

        /// URL of the app's App Store review page.
        public static let review = URL(string: "itms-apps://itunes.apple.com/de/app/\(App.id)?action=write-review")!

        // MARK: Callbacks

        /// URL that is opened in response to a successful authorization.
        public static let signInCallback = URL(string: "http://127.0.0.1:8080/sign-in")!
    }

    // MARK: - Identifiers

    /// Apple App Id as used by the App Store.
    static let id = "1317593772"

    /// Application group identifier used for sharing data between targets.
    static let groupIdentifier = "group.SteffenRyll.StudKit"

    /// Application iCloud container identifier.
    static let iCloudContainerIdentifier = "iCloud.SteffenRyll.StudKit"

    // MARK: - Names

    /// Display name of the application.
    public static let name = Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String

    /// Human-readable version name for this application.
    public static let versionName = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

    /// The application's author.
    public static let authorName = "Steffen Ryll"

    // MARK: - Feedback

    /// Email address to send app feedback to.
    public static let feedbackMailAddress = "studapp@stoeffn.de"

    /// URL scheme registered with this application.
    public static let scheme = "studapp"

    // MARK: - Bundles

    /// Bundle of the `StudKit` framework.
    public static let kitBundle = Bundle(for: StudKitServiceProvider.self)
}

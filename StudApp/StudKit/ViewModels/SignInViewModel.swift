//
//  SignInViewModel.swift
//  StudKit
//
//  Created by Steffen Ryll on 01.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

/// Manages the sign-in view that allows a user to sign into his/her university's Stud.IP account.
///
/// The user interface should provide text fields for the username and the password as well as a button for signing in.
public final class SignInViewModel {
    public enum State {
        /// Initial state inviting the user to enter his/her credentials.
        case idle

        /// The application is currently making a network request, i.e. trying to sign in. The view should show an
        /// indication of that.
        case loading

        /// There was an error signing in. The view should display the associated error.
        case failure(String)

        /// User has been signed in successfully. The view should now show the application's main view.
        case success
    }

    private let coreDataService = ServiceContainer.default[CoreDataService.self]
    private let studIpService = ServiceContainer.default[StudIpService.self]

    /// Current state of the sign-in process, which should be respected by the user interface.
    public var state: State = .idle {
        didSet { stateChanged?(state) }
    }

    /// This handler is called every time `state` changes.
    public var stateChanged: ((State) -> Void)?

    public init() {}

    /// Attempts to sign a user into his/her Stud.IP account after performing basic form validation.
    public func attemptSignIn(withUsername username: String, password: String) {
        guard !username.isEmpty && !password.isEmpty else {
            state = .failure("Please enter your Stud.IP credentials".localized)
            return
        }

        state = .loading
        studIpService.signIn(withUsername: username, password: password) { result in
            switch result {
            case .success:
                self.state = .success
                self.updateSemesters()
            case let .failure(error):
                self.state = .failure(error?.localizedDescription ?? "Please check your username and password".localized)
            }
        }
    }

    private func updateSemesters() {
        coreDataService.performBackgroundTask { context in
            Semester.update(in: context) { _ in
                try? context.saveWhenChanged()
            }
        }
    }
}

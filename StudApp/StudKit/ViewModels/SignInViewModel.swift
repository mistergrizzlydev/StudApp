//
//  SignInViewModel.swift
//  StudKit
//
//  Created by Steffen Ryll on 01.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

public final class SignInViewModel {
    public enum State {
        /// Initial state.
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
    private let semesterService = ServiceContainer.default[SemesterService.self]

    public var state: State = .idle {
        didSet { stateChanged?(state) }
    }

    public var stateChanged: ((State) -> Void)?

    public init() {}

    public func attemptSignIn(withUsername username: String, password: String) {
        guard !username.isEmpty && !password.isEmpty else {
            state = .failure("Please enter your Stud.IP credentials")
            return
        }

        state = .loading
        studIpService.signIn(withUsername: username, password: password) { result in
            switch result {
            case .success:
                self.state = .success
                self.updateSemesters()
            case let .failure(error):
                self.state = .failure(error?.localizedDescription ?? "Please check your username and password")
            }
        }
    }

    public func updateSemesters() {
        coreDataService.performBackgroundTask { context in
            self.semesterService.update(in: context) { _ in
                try? context.saveWhenChanged()
            }
        }
    }
}

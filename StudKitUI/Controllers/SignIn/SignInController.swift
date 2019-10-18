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

import SafariServices
import StudKit

final class SignInController: UIViewController, Routable, SFSafariViewControllerDelegate {
    private var htmlContentService: HtmlContentService!
    private var viewModel: SignInViewModel!
    private var observations = [NSKeyValueObservation]()

    // MARK: - Life Cycle

    deinit {
        observations.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        htmlContentService = ServiceContainer.default[HtmlContentService.self]

        NotificationCenter.default.addObserver(self, selector: #selector(safariViewControllerDidLoadAppUrl(notification:)),
                                               name: .safariViewControllerDidLoadAppUrl, object: nil)

        titleLabel.text = viewModel.organization.title
        areOrganizationViewsHidden = true
        isActivityIndicatorHidden = true

        observations = [
            viewModel.observe(\.state, options: [.initial]) { [weak self] _, _ in
                guard let self = self else { return }
                self.updateUserInterface(for: self.viewModel.state)
            },
            viewModel.observe(\.error) { [weak self] _, _ in
                guard let self = self, let error = self.viewModel.error else { return }
                self.animateWithSpring { self.isActivityIndicatorHidden = true }
                self.present(self.controller(for: error), animated: true, completion: nil)
            },
            viewModel.organization.observe(\.iconData, options: [.initial]) { [weak self] _, _ in
                guard let self = self else { return }
                UIView.transition(with: self.view, duration: 0.1, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                    self.iconView.image = self.viewModel.organization.icon ?? self.viewModel.organization.iconThumbnail
                }, completion: nil)
            },
        ]

        viewModel.updateOrganizationIcon()
        viewModel.startAuthorization()

        iconView.accessibilityIgnoresInvertColors = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        animateWithSpring { self.areOrganizationViewsHidden = false }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        animateWithSpring { self.areOrganizationViewsHidden = true }
    }

    // MARK: - Navigation

    func prepareContent(for route: Routes) {
        guard case let .signIntoOrganization(organization) = route else { fatalError() }
        viewModel = SignInViewModel(organization: organization)
    }

    // MARK: - User Interface

    @IBOutlet var iconView: UIImageView!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var activityIndicator: StudIpActivityIndicator!

    var areOrganizationViewsHidden: Bool = true {
        didSet {
            iconView.transform = areOrganizationViewsHidden ? CGAffineTransform(scaleX: 0.1, y: 0.1) : .identity
            iconView.alpha = areOrganizationViewsHidden ? 0 : 1
            titleLabel.alpha = areOrganizationViewsHidden ? 0 : 1
        }
    }

    var isActivityIndicatorHidden: Bool = false {
        didSet {
            activityIndicator.transform = isActivityIndicatorHidden ? CGAffineTransform(scaleX: 0.1, y: 0.1) : .identity
            activityIndicator.alpha = isActivityIndicatorHidden ? 0 : 1
        }
    }

    private func animateWithSpring(animations: @escaping () -> Void) {
        UIView.animate(withDuration: UI.defaultAnimationDuration, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: animations, completion: nil)
    }

    func controller(for error: Error) -> UIViewController {
        let message = error.localizedDescription
        let controller = UIAlertController(title: Strings.Errors.generic.localized, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: Strings.Actions.retry.localized, style: .default) { _ in
            self.animateWithSpring {
                self.isActivityIndicatorHidden = false
            }
            self.viewModel.retry()
        })
        controller.addAction(UIAlertAction(title: Strings.Actions.cancel.localized, style: .cancel) { _ in
            self.performSegue(withRoute: .unwindToSignIn)
        })
        return controller
    }

    func updateUserInterface(for state: SignInViewModel.State) {
        switch state {
        case .updatingCredentials, .updatingRequestToken:
            animateWithSpring {
                self.isActivityIndicatorHidden = false
            }
        case .authorizing:
            animateWithSpring {
                self.isActivityIndicatorHidden = true
            }
            guard let url = viewModel.authorizationUrl else { return }
            authorize(at: url)
        case .updatingAccessToken:
            animateWithSpring {
                self.isActivityIndicatorHidden = false
            }
            presentedViewController?.dismiss(animated: true, completion: nil)
        case .signingIn:
            break
        case .signedIn:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            performSegue(withRoute: .unwindToApp)
        case .canceled:
            performSegue(withRoute: .unwindToSignIn)
        }
    }

    // MARK: - Authorizing the Application

    private func authorize(at url: URL) {
        guard let controller = htmlContentService.safariViewController(for: url) else {
            return Targets.current.open(url: url, completion: nil)
        }
        controller.delegate = self
        return present(controller, animated: true, completion: nil)
    }

    // MARK: - Notifications

    @objc
    private func safariViewControllerDidLoadAppUrl(notification: Notification) {
        presentedViewController?.dismiss(animated: true, completion: nil)

        guard let url = notification.userInfo?[Notification.Name.safariViewControllerDidLoadAppUrlKey] as? URL else {
            return viewModel.cancel()
        }

        viewModel.finishAuthorization(with: url)
    }

    func safariViewControllerDidFinish(_: SFSafariViewController) {
        viewModel.cancel()
    }
}

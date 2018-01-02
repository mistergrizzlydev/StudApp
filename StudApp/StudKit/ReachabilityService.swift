//
//  ReachabilityService.swift
//  StudKit
//
//  Created by Steffen Ryll on 23.12.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import SystemConfiguration

public final class ReachabilityService: ByTypeNameIdentifiable {
    public static let notificationName = NSNotification.Name(rawValue: "\(typeIdentifier).ReachabilityChanged")

    private let reachability = SCNetworkReachabilityCreateWithName(nil, "apple.com")

    public private(set) var currentReachabilityFlags: SCNetworkReachabilityFlags!

    init() {
        guard let reachability = reachability else {
            fatalError("Cannot create reachability service because `SCNetworkReachabilityCreateWithName` failed.")
        }

        let reference = UnsafeMutableRawPointer(Unmanaged<ReachabilityService>.passUnretained(self).toOpaque())
        var context = SCNetworkReachabilityContext(version: 0, info: reference, retain: nil, release: nil, copyDescription: nil)

        let reachabilityCallback: SCNetworkReachabilityCallBack? = { _, flags, info in
            guard let info = info else { return }
            Unmanaged<ReachabilityService>.fromOpaque(info).takeUnretainedValue().reachabilityChanged(flags: flags)
        }

        if !SCNetworkReachabilitySetCallback(reachability, reachabilityCallback, &context) {
            fatalError("Cannot create reachability service because `SCNetworkReachabilitySetCallback` failed.")
        }
        if !SCNetworkReachabilitySetDispatchQueue(reachability, DispatchQueue.main) {
            fatalError("Cannot create reachability service because `SCNetworkReachabilitySetDispatchQueue` failed.")
        }

        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        self.reachabilityChanged(flags: flags)
    }

    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        guard currentReachabilityFlags != flags else { return }
        currentReachabilityFlags = flags

        NotificationCenter.default.post(name: ReachabilityService.notificationName, object: currentReachabilityFlags)
    }
}

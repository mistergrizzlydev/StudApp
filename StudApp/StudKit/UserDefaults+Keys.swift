//
//  UserDefaults+Keys.swift
//  StudKit
//
//  Created by Steffen Ryll on 18.11.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

extension UserDefaults {
    func lastHistoryTransactionTimestampKey(for target: Targets) -> String {
        return "\(target)-lastHistoryTransactionTimestamp"
    }
}

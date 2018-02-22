//
//  KeychainService.swift
//  StudKit
//
//  Created by Steffen Ryll on 22.02.18.
//  Copyright © 2018 Steffen Ryll. All rights reserved.
//

final class KeychainService {
    // MARK: - Errors

    enum Errors: Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }

    // MARK: - Accessing the Keychain

    func password(for service: String, account: String, accessGroup: String? = nil) throws -> String {
        // Build a query to find the item that matches the service, account and access group.
        var query = keychainQuery(service: service, account: account, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw Errors.noPassword }
        guard status == noErr else { throw Errors.unhandledError(status: status) }

        // Parse the password string from the query result.
        guard
            let existingItem = queryResult as? [String: AnyObject],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
        else { throw Errors.unexpectedPasswordData }

        return password
    }

    func save(password: String, for service: String, account: String, accessGroup: String? = nil) throws {
        // Encode the password into an Data object.
        let encodedPassword = password.data(using: String.Encoding.utf8)!

        do {
            // Check for an existing item in the keychain.
            try _ = self.password(for: service, account: account, accessGroup: accessGroup)

            // Update the existing item with the new password.
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedPassword as AnyObject?

            let query = keychainQuery(service: service, account: account, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw Errors.unhandledError(status: status) }
        } catch Errors.noPassword {
            // No password was found in the keychain. Create a dictionary to save as a new keychain item.
            var newItem = keychainQuery(service: service, account: account, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedPassword as AnyObject?

            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw Errors.unhandledError(status: status) }
        }
    }

    func delete(from service: String, account: String, accessGroup: String? = nil) throws {
        // Delete the existing item from the keychain.
        let query = keychainQuery(service: service, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)

        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw Errors.unhandledError(status: status) }
    }

    private func keychainQuery(service: String, account: String? = nil, accessGroup: String? = nil) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?

        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }

        return query
    }
}

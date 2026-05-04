import Foundation

/// Concrete `KeyValueStorage` implementation using `UserDefaults`.
final class UserDefaultsStorage: KeyValueStorage {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Codable values
    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        // Encode the value to Data and store it under the given key.
        // Errors are wrapped in `StorageError.encodingFailed` for callers to handle.
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed(error)
        }
    }

    func load<T: Decodable>(forKey key: String, as type: T.Type) throws -> T {
        // Retrieve Data from UserDefaults and decode it to the expected type.
        guard let data = userDefaults.data(forKey: key) else {
            throw StorageError.notFound
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error)
        }
    }

    // MARK: - Non‑Codable values
    func save(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func loadAny(forKey key: String) -> Any? {
        userDefaults.object(forKey: key)
    }
}
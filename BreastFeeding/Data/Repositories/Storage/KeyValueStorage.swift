import Foundation

/// A generic key-value storage protocol for persisting and retrieving Codable objects.
protocol KeyValueStorage: AnyObject {
    /// Saves a value for the given key.
    /// - Parameters:
    ///   - value: The Encodable value to store.
    ///   - key: The key under which to store the value.
    /// - Throws: An error if encoding or saving fails.
    func save<T: Encodable>(_ value: T, forKey key: String) throws

    /// Loads a value of the given type for the given key.
    /// - Parameters:
    ///   - key: The key of the value to load.
    ///   - type: The type of the value to load.
    /// - Returns: The Decodable value for the given key.
    /// - Throws: An error if the value is not found, or if decoding fails.
    func load<T: Decodable>(forKey key: String, as type: T.Type) throws -> T

    /// Saves an optional Any value for the given key (for non-Codable values like Date).
    /// - Parameters:
    ///   - value: The optional value to store.
    ///   - key: The key under which to store the value.
    func save(_ value: Any?, forKey key: String)

    /// Loads an Any? value for the given key.
    /// - Parameter key: The key of the value to load.
    /// - Returns: The stored optional value, or nil if not found.
    func loadAny(forKey key: String) -> Any?
}

/// Errors that can occur during storage operations.
enum StorageError: Error {
    /// The requested key was not found in the storage.
    case notFound

    /// An error occurred while encoding the value.
    case encodingFailed(Error)

    /// An error occurred while decoding the value.
    case decodingFailed(Error)
}
import Foundation

public extension String {
    /// Returns a title-cased representation of the string where the first letter of each word is capitalized.
    ///
    /// Examples:
    /// - `"hello world".titleCase` -> `"Hello World"`
    /// - `"ELECTRONICS".titleCase` -> `"Electronics"`
    /// - `"men's clothing".titleCase` -> `"Men's Clothing"`
    /// - `"".titleCase` -> `""`
    var titleCase: String {
        capitalized
    }
}

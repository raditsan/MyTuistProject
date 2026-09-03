import Foundation

public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError(String)
    case serverError(String)
    case noData
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL yang diminta tidak valid."
        case .invalidResponse(let statusCode):
            return "Respon server tidak valid (Status code: \(statusCode))."
        case .decodingError(let message):
            return "Gagal memproses data dari server: \(message)"
        case .serverError(let message):
            return "Terjadi kesalahan pada server: \(message)"
        case .noData:
            return "Data tidak ditemukan."
        case .unknown(let message):
            return "Terjadi kesalahan tidak terduga: \(message)"
        }
    }
}

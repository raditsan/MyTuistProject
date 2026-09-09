import Foundation
import Combine

extension Publisher {
    /// Retries the upstream publisher up to `retries` times with an optional `delay`,
    /// but only if the failure matches the provided `condition`.
    ///
    /// If `condition` evaluates to `false` for a given error (e.g. 401, 404, or decoding error),
    /// the pipeline fails immediately without attempting further retries.
    ///
    /// - Parameters:
    ///   - retries: Maximum number of retry attempts.
    ///   - delay: Delay in seconds before each retry attempt. Default is 0.
    ///   - scheduler: Queue on which to execute the delay. Default is `DispatchQueue.global()`.
    ///   - condition: Closure that determines whether the error is retryable.
    /// - Returns: A publisher that conditionally retries upstream errors.
    public func smartRetry(
        _ retries: Int,
        delay: TimeInterval = 0,
        scheduler: DispatchQueue = DispatchQueue.global(),
        when condition: @escaping (Failure) -> Bool
    ) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            guard retries > 0, condition(error) else {
                return Fail(error: error).eraseToAnyPublisher()
            }

            if delay > 0 {
                return Just(())
                    .delay(for: .seconds(delay), scheduler: scheduler)
                    .setFailureType(to: Failure.self)
                    .flatMap { _ in
                        self.smartRetry(retries - 1, delay: delay, scheduler: scheduler, when: condition)
                    }
                    .eraseToAnyPublisher()
            } else {
                return self.smartRetry(retries - 1, delay: 0, scheduler: scheduler, when: condition)
            }
        }
        .eraseToAnyPublisher()
    }
}

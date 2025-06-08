import Combine
import Foundation
import QuartzCore
import Testing

/// Tries to evaluate an expression for a specified timeout.
/// - Parameters:
///   - timeout: The amount of time to wait to evaluate the expression.
///   - expression: An expression of Boolean type.
public func expression(
    timeout: TimeInterval = 1.0,
    _ expression: @MainActor @escaping () async throws -> Bool
)
    async throws -> Bool
{
    actor ExpressionStatus {
        var isFulfilled = false
        func setIsFulfilled() {
            isFulfilled = true
        }
    }
    let start = CACurrentMediaTime()
    let status = ExpressionStatus()
    while await !status.isFulfilled, CACurrentMediaTime() - start < timeout {
        await Task.yield()
        let task = Task<Bool, Error> { @MainActor in
            return try await expression()
        }
        Task { [status] in
            try await Task.sleep(for: .seconds(timeout))
            if await !status.isFulfilled {
                task.cancel()
            }
        }
        // try await print("Evaluated expression: \(task.value)")
        if try await task.value {
            await status.setIsFulfilled()
        }
    }
    return await status.isFulfilled
}

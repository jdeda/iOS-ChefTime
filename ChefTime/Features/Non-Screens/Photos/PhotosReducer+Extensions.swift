import Foundation

// MARK: - Async Timeout Algorithm.
extension PhotosReducer {
  /// What if...we could call an operator on a task, called ".timeout", where given for: TimeInterval (say we provide seconds)
  /// and an operation that returns some result, after the provided time, cancel the task and throw a cancellation error...
  /// and...we need to be able to use clocks for this...
  
  ///
  /// Execute an operation in the current task subject to a timeout.
  ///
  /// - Parameters:
  ///   - seconds: The duration in seconds `operation` is allowed to run before timing out.
  ///   - operation: The async operation to perform.
  /// - Returns: Returns the result of `operation` if it completed in time.
  /// - Throws: Throws ``TimedOutError`` if the timeout expires before `operation` completes.
  ///   If `operation` throws an error before the timeout expires, that error is propagated to the caller.
  func withTimeout<R>(
    for interval: TimeInterval,
    operation: @escaping @Sendable () async throws -> R
  ) async throws -> R {
    return try await withThrowingTaskGroup(of: R.self) { group in
      let deadline = Date(timeIntervalSinceNow: interval)
      
      // Start actual work.
      group.addTask {
        let result = try await operation()
        try Task.checkCancellation()
        return result
      }
      
      // Start timeout child task.
      group.addTask {
        let interval = deadline.timeIntervalSinceNow
        if interval > 0 {
          try await clock.sleep(for: .nanoseconds(UInt64(interval * 1_000_000_000)))
        }
        try Task.checkCancellation()
        
        // We’ve reached the timeout.
        throw TimedOutError.timedOut
      }
      // First finished child task wins, cancel the other task.
      let result = try await group.next()!
      group.cancelAll()
      return result
    }
  }
  
  enum TimedOutError: Error, Equatable {
    case timedOut
  }
}

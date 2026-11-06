//
//  File.swift
//  
//
//  Created by Yusuf Tör on 08/05/2024.
//

import Foundation

actor TaskCoalescer<Executor: TaskExecutor> {
  private let executor: Executor
  private var activeTasks: [Int: Task<Executor.Output, Error>] = [:]

  init(executor: Executor) {
    self.executor = executor
  }

  func get(using input: Executor.Input) async throws -> Executor.Output {
    let hashValue = input.id.hashValue
    if let existingTask = activeTasks[hashValue] {
      return try await existingTask.value
    }

    let task = Task<Executor.Output, Error> {
      defer { activeTasks[hashValue] = nil }
      return try await executor.perform(using: input)
    }

    activeTasks[hashValue] = task
    return try await task.value
  }
}

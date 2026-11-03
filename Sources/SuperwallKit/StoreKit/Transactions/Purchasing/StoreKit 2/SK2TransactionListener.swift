//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 20/09/2024.
//

import Foundation
import StoreKit

actor SK2TransactionListener {
  private(set) var taskHandle: Task<Void, Never>?
  private var statusTaskHandle: Task<Void, Never>?
  private let shouldFinishTransactions: Bool
  private let factory: HasExternalPurchaseControllerFactory
  private unowned let receiptManager: ReceiptManager

  deinit {
    self.taskHandle?.cancel()
    self.taskHandle = nil
    self.statusTaskHandle?.cancel()
    self.statusTaskHandle = nil
  }

  init(
    shouldFinishTransactions: Bool,
    receiptManager: ReceiptManager,
    factory: HasExternalPurchaseControllerFactory
  ) {
    self.shouldFinishTransactions = shouldFinishTransactions
    self.receiptManager = receiptManager
    self.factory = factory
  }

  func listenForTransactions() {
    self.statusTaskHandle?.cancel()
    // Expiration and grace-period changes may not emit a new transaction, so observe subscription status too.
    self.statusTaskHandle = Task(priority: .utility) { [weak self] in
      for await _ in StoreKit.Product.SubscriptionInfo.Status.updates {
        guard let self = self else { break }
        await self.receiptManager.loadPurchasedProducts(config: nil)
      }
    }
    self.taskHandle?.cancel()
    self.taskHandle = Task(priority: .utility) { [weak self] in
      for await result in Transaction.updates {
        guard let self = self else { break }
        switch result {
        case let .verified(transaction),
          let .unverified(transaction, _):

          if self.shouldFinishTransactions {
            await transaction.finish()
          }

          await receiptManager.loadPurchasedProducts(config: nil)
        }
      }
    }
  }
}

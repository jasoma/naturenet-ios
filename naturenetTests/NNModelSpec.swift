//
//  NNModelSpec.swift
//  NatureNet
//
//  Created by Jason Maher on 2/8/16.
//
//

import Foundation
import CoreData

import Quick
import Nimble

@testable import NatureNet

class NNModelSpec: NNSpec {
    override func spec() {

        describe("searching") {

            beforeEach {
                NNModel.deleteAll(Account.self)
            }

            describe("find") {

                it("should return all matching records") {
                    let done = self.asyncLatch()
                    10.times { Account.random() }
                    NNModel.find(Account.self, request: NSFetchRequest(entityName: String(Account)))
                        .then({ results in
                            expect(results.count).to(equal(10))
                            done.fulfill()
                        })
                        .error { fail("\($0)") }
                    self.waitDone()
                }

                it("should return an empty array if there are no matches") {
                    let done = self.asyncLatch()
                    NNModel.find(Account.self, matching: NSPredicate(format: "username = %@", "Nobody"))
                        .then({ results in
                            expect(results).to(beEmpty())
                            done.fulfill()
                        })
                        .error { fail("\($0)") }
                    self.waitDone()
                }
            }

            describe("findFirst") {

                it("should return only the first record") {
                    10.timesWithCount { i in
                        NNModel.concurrentContext.performBlockAndWait {
                            let account = Account.random()
                            account.uid = i
                            try! account.save()
                        }
                    }
                    let done = self.asyncLatch()
                    NNModel.findFirst(Account.self, matching: NSPredicate(value: true), orderBy: NSSortDescriptor(key: "uid", ascending: true))
                        .then({ result in
                            expect(result?.uid).to(equal(1))
                            done.fulfill()
                        })
                        .error { fail("\($0)") }
                    self.waitDone()
                }

                it("should return nil if there are no matches") {
                    let done = self.asyncLatch()
                    NNModel.findFirst(Account.self, matching: NSPredicate(format: "uid > 10"))
                        .then({ result in
                            expect(result).to(beNil())
                            done.fulfill()
                        })
                        .error { fail("\($0)") }
                    self.waitDone()
                }
            }

            describe("findOne") {

                it("should return the only record") {
                    let account = Account.random()
                    account.username = "test"
                    try! account.save()
                    let done = self.asyncLatch()
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == 'test'"))
                        .then({ result in
                            expect(result?.username).to(equal("test"))
                            done.fulfill()
                        })
                        .error { fail("\($0)") }
                    self.waitDone()
                }

                it("should return nil if there are no matched") {
                    let done = self.asyncLatch()
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == 'notausername'"))
                        .then({ result in
                            expect(result).to(beNil())
                            done.fulfill()
                        })
                        .error { fail("\($0)") }
                    self.waitDone()
                }

                it("should return an error if there are too many matches") {
                    3.times {
                        NNModel.concurrentContext.performBlockAndWait {
                            let account = Account.random()
                            account.username = "duplicate"
                            try! account.save()
                        }
                    }
                    let done = self.asyncLatch()
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == 'duplicate'"))
                        .then({ fail("\($0)") })
                        .error({error in
                            switch error {
                            case ModelErrors.NoUniqueRecord(let found):
                                expect(found.count).to(equal(3))
                            default:
                                fail("incorrect error: \(error)")
                            }
                            done.fulfill()
                        })
                    self.waitDone()
                }
            }

            describe("findOrInsert") {

                it("should return the only record if it exists") {
                    let account = Account.random()
                    let done = self.asyncLatch()
                    NNModel.findOrInsert(Account.self, matching: NSPredicate(format: "username == %@", account.username))
                        .then({ result in
                            expect(result.username).to(equal(account.username))
                            expect(result.inserted).to(beFalse())
                            done.fulfill()
                        })
                        .error({ fail("\($0)") })
                    self.waitDone()
                }

                it("should return a new instance if there are no matches") {
                    let done = self.asyncLatch()
                    NNModel.findOrInsert(Account.self, matching: NSPredicate(format: "username == 'notausername'"))
                        .then({ result in
                            expect(result.inserted).to(beTrue())
                            done.fulfill()
                        })
                        .error({ fail("\($0)") })
                    self.waitDone()
                }

                it("should return an error if there are too many matches") {
                    2.times {
                        NNModel.concurrentContext.performBlockAndWait {
                            let account = Account.random()
                            account.username = "duplicate"
                            try! account.save()
                        }
                    }
                    let done = self.asyncLatch()
                    NNModel.findOrInsert(Account.self, matching: NSPredicate(format: "username == 'duplicate'"))
                        .then({ fail("\($0)") })
                        .error({error in
                            switch error {
                            case ModelErrors.NoUniqueRecord(let found):
                                expect(found.count).to(equal(2))
                            default:
                                fail("incorrect error: \(error)")
                            }
                            done.fulfill()
                        })
                    self.waitDone()
                }
            }
        }
    }
}
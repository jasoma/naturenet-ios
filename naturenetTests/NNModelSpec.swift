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
                    NNModel.find(Account.self, request: NSFetchRequest(entityName: String(Account))) { results, error in
                        expect(error).to(beNil())
                        expect(results?.count).to(equal(10))
                        done.fulfill()
                    }
                    self.waitDone()
                }

                it("should return an empty array if there are no matches") {
                    let done = self.asyncLatch()
                    NNModel.find(Account.self, matching: NSPredicate(format: "username = %@", "Nobody")) { results, error in
                        expect(error).to(beNil())
                        expect(results!).to(beEmpty())
                        done.fulfill()
                    }
                    self.waitDone()
                }
            }

            describe("findFirst") {

                it("should return only the first record") {
                    10.timesWithCount { i in
                        let account = Account.random()
                        account.uid = i
                        try! account.save()
                    }
                    let done = self.asyncLatch()
                    NNModel.findFirst(Account.self, matching: NSPredicate(value: true), orderBy: NSSortDescriptor(key: "uid", ascending: true)) { result, error in
                        expect(error).to(beNil())
                        expect(result?.uid).to(equal(1))
                        done.fulfill()
                    }
                    self.waitDone()
                }

                it("should return nil if there are no matches") {
                    let done = self.asyncLatch()
                    NNModel.findFirst(Account.self, matching: NSPredicate(format: "uid > 10")) { result, error in
                        expect(error).to(beNil())
                        expect(result).to(beNil())
                        done.fulfill()
                    }
                    self.waitDone()
                }
            }

            describe("findOne") {

                it("should return the only record") {
                    let account = Account.random()
                    account.username = "test"
                    try! account.save()
                    let done = self.asyncLatch()
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == 'test'")) { result, error in
                        expect(error).to(beNil())
                        expect(result?.username).to(equal("test"))
                        done.fulfill()
                    }
                    self.waitDone()
                }

                it("should return nil if there are no matched") {
                    let done = self.asyncLatch()
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == 'notausername'")) { result, error in
                        expect(error).to(beNil())
                        expect(result).to(beNil())
                        done.fulfill()
                    }
                    self.waitDone()
                }

                it("should return an error if there are too many matches") {
                    3.times {
                        let account = Account.random()
                        account.username = "duplicate"
                        try! account.save()
                    }
                    let done = self.asyncLatch()
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == 'duplicate'")) { result, error in
                        expect(result).to(beNil())
                        switch error as! ModelErrors {
                        case ModelErrors.NoUniqueRecord(let found):
                            expect(found.count).to(equal(3))
                        default:
                            fail("incorrect error: \(error)")
                        }
                        done.fulfill()
                    }
                    self.waitDone()
                }
            }

            describe("findOrInsert") {

                it("should return the only record if it exists") {
                    let account = Account.random()
                    let done = self.asyncLatch()
                    NNModel.findOrInsert(Account.self, matching: NSPredicate(format: "username == %@", account.username)) { result, error in
                        expect(error).to(beNil())
                        expect(result!.username).to(equal(account.username))
                        expect(result!.inserted).to(beFalse())
                        done.fulfill()
                    }
                    self.waitDone()
                }

                it("should return a new instance if there are no matches") {
                    let done = self.asyncLatch()
                    NNModel.findOrInsert(Account.self, matching: NSPredicate(format: "username == 'notausername'")) { result, error in
                        expect(error).to(beNil())
                        expect(result!.inserted).to(beTrue())
                        done.fulfill()
                    }
                    self.waitDone()
                }

                it("should return an error if there are too many matches") {
                    2.times {
                        let account = Account.random()
                        account.username = "duplicate"
                        try! account.save()
                    }
                    let done = self.asyncLatch()
                    NNModel.findOrInsert(Account.self, matching: NSPredicate(format: "username == 'duplicate'")) { result, error in
                        expect(result).to(beNil())
                        switch error as! ModelErrors {
                        case ModelErrors.NoUniqueRecord(let found):
                            expect(found.count).to(equal(2))
                        default:
                            fail("incorrect error: \(error)")
                        }
                        done.fulfill()
                    }
                    self.waitDone()
                }
            }

        }

    }
}
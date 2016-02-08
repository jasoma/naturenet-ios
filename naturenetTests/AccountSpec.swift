//
//  AccountSpec.swift
//  NatureNet
//
//  Created by Jason Maher on 2/4/16.

@testable import NatureNet

import CoreData
import Quick
import Nimble

class AccountSpec: NNSpec {
    override func spec() {

        describe("interaction with the API server") {

            it("can be created from the data response") {
                let data = Account.randomDictionary()
                let created = NNModel.insert(Account.self)
                try! created.updateWithData(data)
                try! created.save()
                expect(created.uid.integerValue).to(equal(data["id"] as? Int))
                expect(created.username).to(equal(data["username"] as? String))
                expect(created.name).to(equal(data["name"] as? String))
                expect(created.modified_at).to(equal(data["modified_at"] as? Int))
                expect(created.created_at).to(equal(data["created_at"] as? Int))
            }

            it("can be updated from the data response") {
                let done = self.asyncLatch()
                var data = Account.randomDictionary()
                NNModel.findFirst(Account.self, matching: NSPredicate(value: true)) { account, error in
                    expect(error).to(beNil())
                    data["id"] = account!.uid
                    do {
                        try account!.updateWithData(data)
                        try account!.save()
                    } catch {
                        fail("update failed: \(error)")
                    }
                    NNModel.findOne(Account.self, matching: NSPredicate(format: "username == %@", account!.username)) { found, error in
                        expect(error).to(beNil())
                        expect(found).toNot(beNil())
                        expect(found!.username).to(equal(data["username"] as? String))
                        done.fulfill()
                    }
                }
                self.waitDone()
            }
        }
    }
}

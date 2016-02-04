//
//  AccountSpec.swift
//  NatureNet
//
//  Created by Jason Maher on 2/4/16.

@testable import NatureNet

import Quick
import Nimble

class AccountSpec: QuickSpec {
    override func spec() {

        describe("interaction with the API server") {

            let data = [
                "id": 12345,
                "username": "testuser",
                "name": "Test User",
                "modified_at": 1409354549310,
                "created_at": 1409354549310
            ]

            it("can be created from the data response") {
                let saved = Account.saveToCoreData(data)!
                expect(saved.uid).to(equal(data["id"]))
                expect(saved.username).to(equal(data["username"]))
                expect(saved.name).to(equal(data["name"]))
                expect(saved.modified_at).to(equal(data["modified_at"]))
                expect(saved.created_at).to(equal(data["created_at"]))
            }

            it("can be updated from the data response") {
                let user = NNModel.fetechEntitySingle(NSStringFromClass(Account), predicate: NSPredicate(format: "username = %@", "testuser"))!
                var updateData = data
                updateData["name"] = "Updated User"
                updateData["modified_at"] = data["modified_at"] as! Int + 1
                updateData["created_at"] = data["created_at"] as! Int + 1
                user.updateToCoreData(updateData)
                user.commit()

                // currently all errors are trapped behind the call to commit(), only way to know if the operation was
                // successful is to redo the query.
                if let updated = NNModel.fetechEntitySingle(NSStringFromClass(Account), predicate: NSPredicate(format: "name = %@", "Updated User")) as? Account {
                    expect(updated.name).to(equal(updateData["name"]))
                    expect(updated.modified_at).to(equal(updateData["modified_at"]))
                    expect(updated.created_at).to(equal(updateData["created_at"]))
                } else {
                    fail("could not load the account")
                }
            }

            // TODO: remove this if https://github.com/naturenet/naturenet-api/pull/3 is accepted
            it("should tolerate missing name and timestamps") {
                var incomplete = data
                incomplete.removeValueForKey("name")
                incomplete.removeValueForKey("modified_at")
                incomplete.removeValueForKey("created_at")

                if let account = NNModel.fetechEntitySingle(NSStringFromClass(Account), predicate: NSPredicate(format: "username = %@", data["username"]!)) as? Account {
                    expect { try account.updateWithData(incomplete) }.toNot(throwError())
                } else {
                    fail("could not load the account")
                }
            }
        }
    }
}

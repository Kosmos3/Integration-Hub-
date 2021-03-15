//
//  Patiendt.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 22.12.20.
//

import Foundation


struct Patient: Encodable {
    let resourceType = "Patient"
    let meta = Meta.init()
    let name: [NameValues]
    let managingOrganization = ManagingOrg.init()
    let address : [Address]
    let identifier: [Identifier]
    let gender: String
    var birthDate: String? = nil
    var id: String? = nil

}

struct Meta: Encodable {
    let profile = ["https://www.medizininformatik-initiative.de/fhir/core/modul-person/StructureDefinition/Patient"]
}

struct Identifier: Encodable {
    let use: String
    let type: Coding
    let system: String
    let value: String
    let assigner: AssignValues
}

struct NameValues: Encodable {
    let use: String
    let family: String
    var _family: Xtension? = nil
    var given: [String]?
    var prefix: [String]?
    let _prefix: Prefix? = nil
}

struct AssignValues: Encodable {
    var display: String? = nil
    let identifier: IdentifierValues
}

struct IdentifierValues: Encodable {
    var use: String? = nil
    var value: String? = nil
    var system: String? = nil
}

struct Xtension: Encodable {
    let `extension` : [ExtensionValues]
    struct ExtensionValues : Encodable {
        let url : String
        let value : String?
    }
}

struct Prefix: Encodable {
    let `extension` : [ExtensionValues]
    struct ExtensionValues : Encodable {
        let url : String
        let valueString : String?
    }
}

struct Address: Encodable {
    let type = "both"
    let line: [String]
    let city: String
    let state: String
    let postalCode: String
    let country = "DE"
}

struct ManagingOrg: Encodable {
    let reference = "Organization/Charite-Universitaetsmedizin-Berlin"
}


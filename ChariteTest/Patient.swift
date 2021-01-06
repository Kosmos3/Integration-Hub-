//
//  Patiendt.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 22.12.20.
//

import Foundation


struct Patient: Encodable {
    let ressourceType = "Patient"
    let meta = Meta.init()
    let name: [NameValues]
    let managingOrganization = ManagingOrg.init()
}

struct Meta: Encodable {
    let profile = ["https://www.medizininformatik-initiative.de/fhir/core/modul-person/StructureDefinition/Patient"]
}

struct NameValues: Encodable {
    let use: String
    let family: String
    var _family: Xtension? = nil
    var given: [String]?
    var prefix: String?
    let _prefix: Prefix? = nil
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
    let line: String
    let city: String
    let state: String
    let postalCode: Int
    let country = "DE"
}

struct ManagingOrg: Encodable {
    let reference = "Organization/Charite-Universitaetsmedizin-Berlin"
}


//
//  Observation.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 02.12.20.
//

import Foundation
import HealthKit

struct ecgValue: Identifiable {
    let id = UUID()
    let date: Date
    let observationTemplate: ObservationTemplate
    var sent: Bool = false
    let symptoms: [HKCategoryTypeIdentifier]
}

struct ObservationTemplate: Encodable {
    let status = "final"
    let resourceType = "Observation"
    let category = [Coding.init(coding: [CodingValues.init(system: "https://www.hl7.org/fhir/procedure.html", code: "procedure", display: "Procedure")])]
    let device: Device
    let id = "ekg"
    let code = Coding.init(coding: [CodingValues.init(system: "urn:oid:2.16.840.1.113883.6.24", code: "131328", display: "MDC_ECG_ELEC_POTL")])
    let component: [ComponentValues]
    let subject: Subject
    let performer: [Performer]
    let effectiveDateTime: String
}

struct ComponentValues: Encodable {
    let code: Coding?
    var valueSampledData: ValueSampledData? = nil
    var valueCodeableConcept: ValueCodeableConcept? = nil
}

struct ValueSampledData: Encodable {
    let data: String
    let dimensions = 1
    let period = 1.953125
    let origin: Origin
}

struct Origin: Encodable {
    let value = 0;
}

struct Coding: Encodable {
    let coding: [CodingValues]
}

struct CodingValues: Encodable {
    let system: String
    let code: String
    var display: String? = nil
}

struct Device: Encodable {
    let display: String
}

struct Subject: Encodable {
    let display: String?
    let reference: String
}

struct Performer: Encodable {
    let display: String?
    let reference: String
}

struct ValueCodeableConcept: Encodable {
    let coding: [CodingValues]
    let text: String
}

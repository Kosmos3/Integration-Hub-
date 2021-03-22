//
//  MedikationsPlan.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 18.10.20.
//

import Foundation
import HealthKit

class EcgVM: ObservableObject{
    // Add code to use HealthKit here.
    let healthStore = HKHealthStore()
    
    var latestDate : Date? = nil
    
    var descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    var predicate = HKQuery.predicateForSamples(withStart: nil, end: nil)
    
    @Published var ecg = [ecgValue]()
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        authorizeHealthKit()
        //requestSleepAuthorization()
    }
    
    // Function to authorize HealthKit on every start of the app
    func authorizeHealthKit() {
        let electroCarido = Set([HKObjectType.electrocardiogramType(),
                                 HKObjectType.categoryType(forIdentifier: .rapidPoundingOrFlutteringHeartbeat)!,
                                 HKObjectType.categoryType(forIdentifier: .skippedHeartbeat)!,
                                 HKObjectType.categoryType(forIdentifier: .fatigue)!,
                                 HKObjectType.categoryType(forIdentifier: .shortnessOfBreath)!,
                                 HKObjectType.categoryType(forIdentifier: .chestTightnessOrPain)!,
                                 HKObjectType.categoryType(forIdentifier: .fainting)!,
                                 HKObjectType.categoryType(forIdentifier: .dizziness)!])
        
        healthStore.requestAuthorization(toShare: nil, read: electroCarido) { (sucess, error) in
            if sucess {
                print("HealthKit Auth successful")
                self.readEcgData()
            } else {
                print("HealthKit Auth Error")
            }
        }
    }
    
    func readEcgData() {
        // Create the electrocardiogram sample type.
        let ecgType = HKObjectType.electrocardiogramType()
        // Query for electrocardiogram samples
        let ecgQuery = HKSampleQuery(sampleType: ecgType,
                                     predicate: predicate,
                                     limit: HKObjectQueryNoLimit,
                                     sortDescriptors: [descriptor]) { (query, samples, error) in
            if let error = error {
                // Handle the error here.
                fatalError("*** An error occurred \(error.localizedDescription) ***")
            }
            
            guard let ecgSamples = samples as? [HKElectrocardiogram] else {
                fatalError("*** Unable to convert \(String(describing: samples)) to [HKElectrocardiogram] ***")
            }
            
            print("Actual predicate: \(self.predicate)")
            print("LatestDate: \(String(describing: self.latestDate))")
            for sample in ecgSamples {
                print("SYMPTOM STATUS: \(sample.symptomsStatus == .present)")
                print("Status \(sample.symptomsStatus.rawValue)")
                self.getAllSymptoms(from: sample) { HKCategoryTypeIdentifier in
                    let categoryIdentifier = HKCategoryTypeIdentifier
                    
                    var dataDecimal = [Decimal]()
                    let voltageQuery = HKElectrocardiogramQuery(sample) { (query, result) in
                        switch(result) {
                        case .measurement(let measurement):
                            if let voltageQuantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                                let voltageValue = (voltageQuantity.value(forKey: "value") as! NSNumber).decimalValue
                                dataDecimal.append(voltageValue)
                            }
                        case .done:
                            print()
                            print("Done Entry")
                            let voltageValue = self.formatValues(data: "\(dataDecimal)")
                            print("DATA DECIMAL \(dataDecimal.count)")
                            let observationEcg = self.createObservation(sample: sample, voltageValue: voltageValue, symptoms: categoryIdentifier)
                            //printJSON(data: observationEcg)
                            let ecgValue = ecgValue.init(date: sample.startDate, observationTemplate: observationEcg, symptoms: categoryIdentifier)
                            print("Eingefügt wird: \(sample.startDate)")
                            // TODO: Restructure
                            DispatchQueue.main.async {
                                self.ecg.append(ecgValue)
                                self.ecg.sort {
                                    $0.date > $1.date
                                }
                                self.latestDate = self.ecg[0].date
                                self.predicate = NSPredicate(format: "%K > %@", HKPredicateKeyPathStartDate, self.latestDate! as NSDate)
                                print("LatestDate: \(self.latestDate!)")
                                print()
                            }
                            print("Done")
                        case .error(let error):
                            print(error)
                        @unknown default:
                            print("Default")
                        }
                    }
                    // Execute the electrocardiogram query
                    self.healthStore.execute(voltageQuery)
                }
            }
            print("END For Loop")
        }
        // Execute the sample query.
        healthStore.execute(ecgQuery)
    }
    
    func createObservation(sample: HKElectrocardiogram, voltageValue: String, symptoms: [HKCategoryTypeIdentifier]) -> ObservationTemplate {
        let name = "/Patient/\(userDefaults.string(forKey: "Output")!)"
        let deviceInit = Device.init(display: sample.sourceRevision.productType ?? "Old Device")
        let effectiveDateTime = self.getISODateFromDate(date: sample.startDate)
        let performerInit = Performer.init(display: name,
                                           reference: name)
        let subjectInit = Subject.init(display: name,
                                       reference: name)
        let valueSampleDataInit = ValueSampledData.init(data: voltageValue,
                                                        origin: Origin.init())
        let componenValuesInit = [ComponentValues.init(code:
                                                        Coding.init(coding:
                                                                        [CodingValues.init(system: "urn:oid:2.16.840.1.113883.6.24",
                                                                                           code: "131329",
                                                                                           display: "MDC_ECG_ELEC_POTL_I")]),
                                                       valueSampledData: valueSampleDataInit)
        ]
        
        return ObservationTemplate.init(device: deviceInit,
                                        component: componenValuesInit + getClassification(sample: sample) + getSymptomsFHIR(symptoms: symptoms),
                                        subject: subjectInit,
                                        performer: [performerInit],
                                        effectiveDateTime: effectiveDateTime)
    }
    
    func getSymptomsFHIR(symptoms: [HKCategoryTypeIdentifier]) -> [ComponentValues] {
        let coding: Coding = Coding.init(coding: [CodingValues.init(system: "https://loinc.org",
                                                                    code: "75325-1",
                                                                    display: "Symptom")])
        var output: [ComponentValues] = []
        for categoryIdentifier in symptoms {
            print("CATE \(categoryIdentifier)")
            let codingValues: [CodingValues]
            let value: ValueCodeableConcept
            switch categoryIdentifier {
            case .rapidPoundingOrFlutteringHeartbeat:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "80313002",
                                                  display: "Palpitations (finding)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Palpitations (finding)")
            case .skippedHeartbeat:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "248653008",
                                                  display: "Dropped beats")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Dropped beats")
            case .fatigue:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "84229001",
                                                  display: "Fatigue (finding)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Fatigue (finding)")
            case .shortnessOfBreath:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "267036007",
                                                  display: "Dyspnea (finding)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Dyspnea (finding)")
            case .chestTightnessOrPain:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "23924001",
                                                  display: "Tight chest (finding)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Tight chest (finding)")
            case .fainting:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "271594007",
                                                  display: "Syncope (disorder)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Syncope (disorder)")
            case .dizziness:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "404640003",
                                                  display: "Dizziness (finding)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "Dizziness (finding)")

            default:
                codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                                  code: "260413007",
                                                  display: "None (qualifier value)")]
                value = ValueCodeableConcept.init(coding: codingValues,
                                                  text: "None (qualifier value)")
            }
            output.append(ComponentValues.init(code: coding, valueCodeableConcept: value))
        }
        return output
    }
        
    // TODO Finish it
    func getClassification(sample: HKElectrocardiogram) -> [ComponentValues] {
        let coding: Coding = Coding.init(coding: [CodingValues.init(system: "http://snomed.info/sct",
                                                                    code: "271921002",
                                                                    display: "Electrocardiogram finding")])
        let codingValues: [CodingValues]
        let value: ValueCodeableConcept
        switch sample.classification {
        case .atrialFibrillation:
            codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                              code: "164889003",
                                              display: "Electrocardiographic atrial fibrillation")]
            value = ValueCodeableConcept.init(coding: codingValues,
                                              text: "classification")
        case .inconclusiveHighHeartRate:
            codingValues = [CodingValues.init(system: "http://snomed.info/sct",
                                              code: "442754001",
                                              display: "Inconclusive evaluation finding")]
            value = ValueCodeableConcept.init(coding: codingValues,
                                              text: "classification")
        case .inconclusiveLowHeartRate:
            return []
        case .inconclusiveOther:
            return []
        case .inconclusivePoorReading:
            return []
        case .sinusRhythm:
            return []
        case .unrecognized:
            return []
        case .notSet:
            return []
        default:
            return []
        }
        return [ComponentValues.init(code: coding, valueCodeableConcept: value)]
    }
    
    func getAllSymptoms(from sample: HKElectrocardiogram, completion: @escaping ([HKCategoryTypeIdentifier]) -> Void) {
        let catIds: [HKCategoryTypeIdentifier] =  [
            .rapidPoundingOrFlutteringHeartbeat,
            .skippedHeartbeat,
            .fatigue,
            .shortnessOfBreath,
            .chestTightnessOrPain,
            .fainting,
            .dizziness,
        ]
        var output: [HKCategoryTypeIdentifier] = []
        let group = DispatchGroup()
        for catId in catIds {
            group.enter()
            getSymptoms(from: sample, categoryType: catId, group: group) {
                (cat: HKCategoryTypeIdentifier, userEntered: Bool) in
                DispatchQueue.main.async {
                    if userEntered {
                        output.append(cat)
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(output)
        }        
    }
    
    func getSymptoms(from sample: HKElectrocardiogram,
                     categoryType: HKCategoryTypeIdentifier,
                     group: DispatchGroup,
                     completion: @escaping (HKCategoryTypeIdentifier, Bool)->Void){
        guard sample.symptomsStatus == .present,
              let sampleType = HKSampleType.categoryType(forIdentifier: categoryType) else {
            completion(categoryType, false)
            return
        }
        let predicate = HKQuery.predicateForObjectsAssociated(electrocardiogram: sample)
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: predicate,
                                        limit: HKObjectQueryNoLimit,
                                        sortDescriptors: nil) { (query, samples, error) in
            if (samples?.first) != nil {
                completion(categoryType, true)
            } else {
                completion(categoryType, false)
            }
        }
        healthStore.execute(sampleQuery)
    }
    
    // Function to extract brackets and ";" from the Ecg values
    func formatValues(data : String) -> String {
        return data.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: ",", with: "")
    }
    
    func getISODateFromDate(date: Date) -> String {
        return ISO8601DateFormatter().string(from: date)
    }
    
    func getDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: date)
    }
}

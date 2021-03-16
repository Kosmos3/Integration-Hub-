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
    }
        
    // Function to authorize HealthKit on every start of the app
    func authorizeHealthKit() {
        let electroCarido = Set([HKObjectType.electrocardiogramType()])
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
            
            print(self.predicate)
            print("LatestDate \(String(describing: self.latestDate))")
            print("Samples: \(ecgSamples)")
            for sample in ecgSamples {
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
                        let string = self.formatValues(data: "\(dataDecimal)")
                        let observationEcg = self.createObservation(sample: sample, string: string)
                        //printJSON(data: observationEcg)
                        let testIDObject = ecgValue.init(date: sample.startDate, observationTemplate: observationEcg)
                        print("Eingefügt wird: \(sample.startDate)")
                        // TODO: Restructure
                        DispatchQueue.main.async {
                            self.ecg.append(testIDObject)
                            self.ecg.sort {
                                $0.date > $1.date
                            }
                            self.latestDate = self.ecg[0].date
                            self.predicate = NSPredicate(format: "%K > %@", HKPredicateKeyPathStartDate, self.latestDate! as NSDate)
                            print(self.latestDate!)
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
            print("END For Loop")
        }
        // Execute the sample query.
        healthStore.execute(ecgQuery)
    }
    
    func createObservation(sample : HKElectrocardiogram, string : String) -> ObservationTemplate {
        let name = "/Patient/\(userDefaults.string(forKey: "Output")!)"
        let deviceInit = Device.init(display: sample.sourceRevision.productType ?? "Old Device")
        let effectiveDateTime = self.getISODateFromDate(date: sample.startDate)
        let performerInit = Performer.init(display: name, reference: name)
        let subjectInit = Subject.init(display: name, reference: name)
        let valueSampleDataInit = ValueSampledData.init(data: string, origin: Origin.init())
        let componenValuesInit = ComponentValues.init(valueSampledData: valueSampleDataInit)
        return ObservationTemplate.init(device: deviceInit, component: [componenValuesInit], subject: subjectInit, performer: [performerInit], effectiveDateTime: effectiveDateTime)
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

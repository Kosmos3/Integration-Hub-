//
//  RegisterLogin.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 24.12.20.
//

import SwiftUI
import HealthKit

let store = HKHealthStore()

struct RegisterLogin: View {
    @State private var surName: String = ""
    @State private var lastName: String = ""
    @State private var birthName: String = ""
    @State private var selectedGenderIndex: Int = -1
    @State private var birthDate = Date()
    @State private var adresse: String = ""
    @State private var stadt: String = ""
    @State private var country: String = ""
    @State private var postalCode: Int = 12345
    @State private var countries: [String] = []
    private var genderOptions = ["🙍‍♂️ Männlich", "🙍‍♀️ Weiblich", "🤖 Divers"]
    
    init() {
        authorizeHealthStore()
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Geschlecht")) {
                    Picker("Gender", selection: $selectedGenderIndex) {
                        ForEach(0..<genderOptions.count) {
                            Text(self.genderOptions[$0])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Name")) {
                    HStack {
                        TextField("Vorname", text: $surName)
                        if !surName.isEmpty {
                            Button(action: {
                                self.surName = ""
                            }, label: {
                                Image(systemName: "delete.left")
                                    .foregroundColor(Color(UIColor.opaqueSeparator))
                            })
                        }
                    }
                    HStack {
                        TextField("Nachname", text: $lastName)
                        if !lastName.isEmpty {
                            Button(action: {
                                self.lastName = ""
                            }, label: {
                                Image(systemName: "delete.left")
                                    .foregroundColor(Color(UIColor.opaqueSeparator))
                            })
                        }

                    }
                    HStack {
                        TextField("Geburtsname", text: $birthName)
                        if !birthName.isEmpty {
                            Button(action: {
                                self.birthName = ""
                            }, label: {
                                Image(systemName: "delete.left")
                                    .foregroundColor(Color(UIColor.opaqueSeparator))
                            })
                        }
                    }
                }
                Section(header: Text("Geburtsdatum")) {
                                    DatePicker(selection: $birthDate, displayedComponents: [.date], label: { Text("Date") }).labelsHidden() // TODO Workarround to fix constraints
                }
                Section(header: Text("Adresse")) {
                    TextField("Adresse", text: $adresse) // TODO Autocomplete
                    Picker(selection: $country, label: Text("Land")) {
                        ForEach(countries, id: \.self) {country in
                            Text(country)
                        }
                    }.onAppear{
                        getCountries()
                    }
                }
                Section {
                    Button("Test") {
                        test123()
                    }.disabled(surName.isBlank || lastName.isBlank || selectedGenderIndex == -1)
                }
            }
            .navigationBarTitle("Registrierung")
            .navigationBarItems(trailing:
                                    Button("TestTop") {
                                        authorizeHealthStore()
                                    })
            
            .onAppear {
                readHKData()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    func getCountries() {
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            countries.append(name)
        }
        print("Countries: \(countries.count)")
    }
    
    func test123() {
        let `extension` = Xtension.init(extension: [Xtension.ExtensionValues.init(url: "http://hl7.org/fhir/StructureDefinition/humanname-own-name", value: lastName.withoutWhitespace)])
        let name = NameValues.init(use: "official", family: lastName.withoutWhitespace, _family: `extension`, given: surName.split(separator: " ").map { String($0) }, prefix: "qwe")
        let birthname = NameValues.init(use: "maiden", family: birthName)
        
        let patient = Patient.init(name: birthName.isBlank ? [name] : [name, birthname])
        printJSON(observation: patient)
    }
    
    func readHKData() {
        print("Reading HK Data readHKData")
        do {
            print("HK Data:")
            let birthDate = try store.dateOfBirthComponents().date
            let gender = try store.biologicalSex().biologicalSex
            let genderInt: Int
            switch gender {
            case .female:
                genderInt = 1
            case .male:
                genderInt = 0
            case .other:
                genderInt = 2
            default:
                genderInt = -1
            }
            self.selectedGenderIndex = genderInt
            self.birthDate = birthDate!
            print(genderInt)
            print(self.birthDate)
        } catch {
            print("Something went wrong: \(error)")            
        }
    }
    
    func authorizeHealthStore() {
        let electroCarido = Set([HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
                                 HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!])
        store.requestAuthorization(toShare: nil, read: electroCarido) { (sucess, error) in
            if sucess {
                print("HealthKit Auth successful")
                readHKData()
            } else {
                print("HealthKit Auth Error")
            }
        }
    }
}



func printJSON(observation : Patient) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    let data = try! encoder.encode(observation)
    print(String(data: data, encoding: .utf8)!)
}

struct RegisterLogin_Previews: PreviewProvider {
    static var previews: some View {
        RegisterLogin()
    }
}

extension String {
    var isBlank: Bool {
        return allSatisfy({ $0.isWhitespace })
    }
    var withoutWhitespace: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

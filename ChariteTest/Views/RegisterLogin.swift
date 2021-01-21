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
    // Section Geschlecht
    private var genderOptions = ["🙍‍♂️ Männlich", "🙍‍♀️ Weiblich", "🤖 Divers"]
    // Section Name
    @State private var surName: String = "Maja Julia"
    @State private var lastName: String = "Van-der-Dusen"
    @State private var birthName: String = "Haffer"
    @State private var selectedGenderIndex: Int = 1 // -1
    @State private var prefix: String = "Prof. Dr. med."
    // Section Birthdate
    @State private var birthDate = Date()
    // Section Address
    @State private var address: String = "Anna-Louisa-Karsch Str. 2"
    @State private var city: String = "Berlin"
    @State private var state: String = "Berlin"
    @State private var postalCode: Int = 10178 // TODO Numeric keyboard
    @State private var countryCode: String = "DE"
    // Section Krankenkasse
    @State private var kkValue: String = "Z234567890"
    // Search Country NOT BEING USED
    @State private var country: String = ""
    @State private var searchTerm: String = ""
    @State private var pickerSelection: String = ""
    var countries: [String] = []
    // Determines if the user is signed in
    @Binding var signInSuccess: Bool
    // UserDeaulf for saving data
    private let userDefaults = UserDefaults.standard
    // Server address
    @State private var serverAddress: String = UserDefaults.standard.string(forKey: "Address") ?? ""
    
    @State var alertController: UIAlertController! // Alternative?
    
    init(signedIn: Binding<Bool>) {
        self._signInSuccess = signedIn
        getCountries()
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
                        TextField("Titel", text: $prefix)
                        if !prefix.isEmpty {
                            Button(action: {
                                self.prefix = ""
                            }, label: {
                                Image(systemName: "delete.left")
                                    .foregroundColor(Color(UIColor.opaqueSeparator))
                            })
                        }
                    }
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
                // TODO Workarround to fix constraints and display Date
                Section(header: Text("Geburtsdatum")) {
                    DatePicker(selection: $birthDate, displayedComponents: [.date], label: { Text("Datum")}) // Apple's bug
                }
                Section(header: Text("Adresse")) {
                    TextField("Adresse", text: $address) // TODO Autocomplete
                    TextField("Bundesland", text: $state) // TODO Autocomplete
                    TextField("Stadt", text: $city) // TODO Autocomplete
                    TextField("Ländercode", text: $countryCode) // TODO Autocomplete
                    TextField("Postleitzahl", value: $postalCode, formatter: NumberFormatter()) // TODO Autocomplete

                }
                Section(header: Text("Krankenkasse")) {
                    TextField("Krankenkassenummer", text: $kkValue) // TODO Autocomplete
                }
                
                Section {
                    Button("Registrieren") {
                        createJSON()
                    }.disabled(surName.isBlank || lastName.isBlank || selectedGenderIndex == -1 || serverAddress.isBlank) // TODO Complete
                }
            }
            .navigationBarTitle("Registrierung")
            .navigationBarItems(leading:
                                    Button(action: {
                                        alertView()
                                    }, label: {
                                        Image(systemName: "network").foregroundColor(buttonColor)
                                    }),
                                trailing:
                                    Button("GetID") {
                                        print(userDefaults.string(forKey: "Output") ?? "ID UserDefaults is empty")
                                        
                                    })
            .onAppear {
                print("onAppear Start:")
                readHKData()
                print("onAppear End \n")
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Determines the color of the server icon
    var buttonColor: Color {
        return serverAddress.isBlank ? .red : .green
    }
    
    // Gets a list of all the countries
    mutating func getCountries() {
        for code in NSLocale.isoCountryCodes  {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            countries.append(name)
        }
        print("Countries: \(countries.count)")
    }
    
    //
    var filteredCountries: [String] {
        countries.filter {
            searchTerm.isEmpty ? true : $0.lowercased().contains(searchTerm.lowercased())
        }
    }
    
    // This funtion creates a JSON for the request
    func createJSON() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        
        //let `extension` = Xtension.init(extension: [Xtension.ExtensionValues.init(url: "http://hl7.org/fhir/StructureDefinition/humanname-own-name", value: lastName.withoutWhitespace)])
        let name = NameValues.init(use: "official", family: lastName.withoutWhitespace, given: surName.split(separator: " ").map { String($0) }, prefix: [prefix]) // _family: `extension`,
        let birthname = NameValues.init(use: "maiden", family: birthName)
        
        let address2 = Address.init(line: [address], city: city, state: state, postalCode: postalCode)
        
        //let identifier1 = Identifier.init(use: "usual", type: Coding.init(coding: [CodingValues.init(system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: "MR")]), system: "https://www.medizininformatik-initiative.de/fhir/core/NamingSystem/patient-identifier", value: String(42285243))
        let identifiert2 = Identifier.init(use: "official", type: Coding.init(coding: [CodingValues.init(system: "http://fhir.de/CodeSystem/identifier-type-de-basis", code: "GKV")]), system: "http://fhir.de/NamingSystem/gkv/kvid-10", value: kkValue, assigner: AssignValues.init(identifier: IdentifierValues.init(use: "official", value: "109519005", system: "http://fhir.de/NamingSystem/arge-ik/iknr")))
        
        let patient = Patient.init(name: birthName.isBlank ? [name] : [name, birthname], address: [address2], identifier: [ identifiert2], gender: getGenderString(genderInt: selectedGenderIndex), birthDate: dateFormatter.string(from: birthDate))
        print("JSON created")
        printJSON(data: patient)
        print("Sending data")
        // TODO: Restructure
        //let test = surName.split(separator: " ").map { String($0) } //TODO FIX
        let one = lastName
        let two = dateFormatter.string(from: birthDate)
        
        getData(lastName: one, birthDate: two, postalCode: postalCode) { (total) in
            if total == 0 {
                sendData(data: patient) // Completion handler here
                self.signInSuccess = true
                userDefaults.set(true, forKey: "signedIn")
            } else {
                DispatchQueue.main.async {
                    let errorAlert = UIAlertController(title: "Server", message: "Die eingegebene Daten sind bereits auf dem Server vorhanden", preferredStyle: .alert)
                    let close = UIAlertAction(title: "Schließen", style: .destructive) { (UIAlertAction) in
                        
                    }
                    errorAlert.addAction(close)
                    UIApplication.shared.windows.first?.rootViewController?.present(errorAlert, animated: true, completion: {
                        print("Showing user already in database alert")
                    })
                }
            }
        }
    }
    
    func readHKData() {
        print("Reading HK Data readHKData")
        do {
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
        } catch {
            print("Something went wrong: \(error)")            
        }
    }
    
    func authorizeHealthStore() {
        let personalData = Set([HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
                                 HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!])
        store.requestAuthorization(toShare: nil, read: personalData) { (sucess, error) in
            if sucess {
                print("HealthKit Auth successful")
                readHKData()
            } else {
                print("HealthKit Auth Error")
            }
        }
    }
    
    func getGenderString(genderInt: Int) -> String {
        if genderInt == 0 {
            return "male"
        } else if genderInt == 1 {
            return "female"
        } else {
            return "other"
        }
    }
    
    // TODO Gültigkeit der Adresse prüfen
    func alertView() {
        var message: String = ""
        
        if let address = userDefaults.string(forKey: "Address") {
            if address.isBlank {
                message = "Bitte Serveradresse eingeben "
            } else {
                message = "Bitte Serveradresse eingeben \n Aktuelle Adresse: \n \(address)"
            }
        } else {
            message = "Bitte Serveradresse eingeben"
        }
        
        alertController = UIAlertController(title: "Server", message: message, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            let url = alertController.textFields![0].text!
            if verifyUrl(urlString: url) {
                userDefaults.set(alertController.textFields![0].text!, forKey: "Address")
                serverAddress = alertController.textFields![0].text!
                print("Adress: \(serverAddress)")
                print("SET")
            } else {
                let errorAlert = UIAlertController(title: "Server", message: "Die eingegebene Serveradresse ist falsch", preferredStyle: .alert)
                let close = UIAlertAction(title: "Schließen", style: .destructive) { (UIAlertAction) in
                    
                }
                errorAlert.addAction(close)
                UIApplication.shared.windows.first?.rootViewController?.present(errorAlert, animated: true, completion: {
                    print("Showing adress is wrong alert")
                })
            }
        }
        
        alertController.addTextField { (addr) in
            addr.placeholder = userDefaults.string(forKey: "Address")
            if let addressQ = userDefaults.string(forKey: "Address") {
                addr.text = addressQ
            } else {
                addr.text = "http://"
            }
        }
        
        let close = UIAlertAction(title: "Abbrechen", style: .destructive) { (_) in }
        
        alertController.addAction(close)
        alertController.addAction(ok)
        
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: {
            print("Showing Alert")
        })
    }
    
    // TODO: Implement regex
    func verifyUrl (urlString: String?) -> Bool {
       if let urlString = urlString {
           if let url = NSURL(string: urlString) {
               return UIApplication.shared.canOpenURL(url as URL)
           }
       }
       return false
   }
}

//struct RegisterLogin_Previews: PreviewProvider {
//    static var previews: some View {
//        RegisterLogin()
//    }
//}

// Extension of the type string
extension String {
    // Determines if the String is blank
    var isBlank: Bool {
        return allSatisfy({ $0.isWhitespace })
    }
    var withoutWhitespace: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

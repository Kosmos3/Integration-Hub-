//
//  Server.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 15.01.21.
//

import Foundation

// TODO Dynamically use the function maybe?
func sendData(data: Patient) {
    let url = URL(string: "\(UserDefaults.standard.string(forKey: "Address")!)/Patient")
    
    guard let requestUrl = url else { fatalError() }

    var request = URLRequest(url: requestUrl)
    request.httpMethod = "POST"
    request.setValue("application/fhir+json; fhirVersion=4.0", forHTTPHeaderField: "Content-Type")
    request.setValue("application/fhir+json; fhirVersion=4.0", forHTTPHeaderField: "Accept")

    let postString = getJSONString(data: data)
    let data = postString.data(using: .utf8)
    request.httpBody = data

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("error \(httpResponse.statusCode)")
                if httpResponse.statusCode == 201 {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        let data = dataString.data(using: .utf8)!
                        do {
                            let output = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                            let id = output!["id"]! as? String
                            let userDefaults = UserDefaults.standard
                            userDefaults.set(id, forKey: "Output")
                            print("Saving value into key (Output): \(userDefaults.string(forKey: "Output") ?? "Error while saving value")")
                        }
                        catch {
                            print (error)
                        }
                        print("Response data string:\n \(dataString)")
                    }
                } else {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Response data string:\n \(dataString)")
                    }
                }
            }
    }
    task.resume()
}

func printJSON<T: Encodable>(data: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    let data = try! encoder.encode(data)
    print(String(data: data, encoding: .utf8)!)
}

func getJSONString<T: Encodable>(data : T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    let data = try! encoder.encode(data)
    return String(data: data, encoding: .utf8)!
}

//
//  Server.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 15.01.21.
//

import Foundation

// TODO Dynamically use of this function
func sendData(data: Patient, completion: @escaping (_ statusCode: Int?) -> Void) {
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
                print("Send data status code: \(httpResponse.statusCode)")
                completion(httpResponse.statusCode)
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
                        print("Response data string 201:\n \(dataString)")
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

// TODO Dynamically use of this function
func getData(lastName: String, birthDate: String, postalCode:String, completion: @escaping (_ total: Int?) -> Void) {
    var url = URLComponents(string: "\(UserDefaults.standard.string(forKey: "Address")! + "/Patient")")
    url?.query = "family=\(lastName)&birthdate=\(birthDate)&address-postalcode=\(postalCode)&_summary=count"
    
    guard let requestUrl = url else { fatalError() }

    var request = URLRequest(url: requestUrl.url!)
    request.httpMethod = "GET"
    
    print("Request from URL \(url!)")
    
    var total: Int = 0
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error took place \(error)")
            completion(-1)
            return
        }
        
        if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    let data = dataString.data(using: .utf8)!
                    do {
                        let output = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]
                        total = output!["total"]! as? Int ?? -1
                        print("Total: \(total)")
                        completion(total)
                    }
                    catch {
                        print (error)
                    }
                    //print("Response data string:\n \(dataString)")
                }
            } else {
                completion(-1)
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

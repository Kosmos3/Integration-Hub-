//
//  User.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 14.03.21.
//

import Foundation

/*
    This struct stores the registered user
 */
struct User {
    var selectedGenderIndex: Int
    
    var surName: String
    var lastName: String
    var prefix: String
    var birthDate: Date
    
    var city: String
    var state: String
    var postalCode: Int
    var countryCode: String
    
    var kkValue: String
}

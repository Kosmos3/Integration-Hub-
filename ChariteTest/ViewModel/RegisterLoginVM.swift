//
//  RegisterLogin.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 14.03.21.
//

import Foundation

final class RegisterLoginVM: ObservableObject {
    
    @Published var user = User(selectedGenderIndex: -1,
                               surName: "",
                               lastName: "",
                               prefix: "",
                               birthDate: Date(),
                               city: "",
                               state: "",
                               postalCode: 123567,
                               countryCode: "",
                               kkValue: "")
}

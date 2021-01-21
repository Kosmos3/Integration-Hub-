//
//  ContentView.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 13.08.20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Home()
    }
}

struct Home: View {
    
    @State var signInSuccess = UserDefaults.standard.bool(forKey: "signedIn")
    
    var body: some View {
        if signInSuccess {
            PullToRefreshView()
                .transition(.move(edge: .trailing))
                .animation(Animation.linear(duration: 0.5))
        } else {
            RegisterLogin(signedIn: $signInSuccess)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

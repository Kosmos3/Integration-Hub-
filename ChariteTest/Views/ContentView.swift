//
//  ContentView.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 13.08.20.
//

import SwiftUI

/*
    This view is the main view that will display the Home view.
 */
struct ContentView: View {
    var body: some View {
        Home()
    }
}

/*
    This is the home view that decides which view to show.
    It depends if the user is logged in or not.
    If the user is not logged in then it will display the RegisterLogin
    view. After completing the registration, the home view will change to
    the ECGView.
 */
struct Home: View {
    /*
        This state saves if the user is logged in or not. The key is
        stored in UserDefaults
     */
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

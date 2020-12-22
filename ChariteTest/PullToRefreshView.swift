//
//  PullToRefreshView.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 14.12.20.
//

import SwiftUI

struct PullToRefreshView: View {
    @ObservedObject var ecg = EcgTest()
    init() {
        ecg.authorizeHealthKit()
    }
    @State var arrayData = ["Test", "Test2", "Test3"]
    @State var refresh = Refresh.init(started: false, released: false, invalid: false)
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ECG")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.purple)
                Spacer()
                Button(action: {sendData()}, label: {
                    Text("Send Data")
                })
            }
            .padding()
            .background(Color.white.ignoresSafeArea(.all, edges: .top))
            Divider()
            ScrollView(.vertical, showsIndicators: false, content: {
                
                // Geometry reader for the "PullToRefresh" action
                GeometryReader {reader -> AnyView in
                    //print(reader.frame(in: .global).minY)
                    DispatchQueue.main.async {
                        if refresh.startOffset == 0 {
                            refresh.startOffset = reader.frame(in: .global).minY
                        }
                        
                        refresh.offset = reader.frame(in: .global).minY
                        
                        if refresh.offset - refresh.startOffset > 80 && !refresh.started {
                            refresh.started = true
                        }
                        
                        if refresh.started && refresh.startOffset == refresh.offset && !refresh.released {
                            withAnimation(Animation.linear) {
                                refresh.released = true
                            }
                            updateData()
                            
                            //refresh.started = false
                            //ecg.readEcgData()
                        }
                        
                        if refresh.started && refresh.startOffset == refresh.offset && refresh.released && refresh.invalid {
                            refresh.invalid = false
                            updateData()
                        }
                    }
                    
                    return AnyView(Color.black.frame(width: 0, height: 0))
                }.frame(width: 0, height: 0)
                
                ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
                    if refresh.started && refresh.released {
                        ProgressView()
                            .offset(y: -35)
                    } else {
                        // Arrow
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.gray)
                            .rotationEffect(.init(degrees: refresh.started ? 180 : 0))
                            .offset(y: -25)
                            .animation(.easeIn)
                    }
                    VStack {
                        ForEach(ecg.testID) { value in
                        //ForEach(arrayData, id: \.self) { value in
                            Divider() // For the lines between Data
                            HStack {
                                Text(value.observationTemplate.effectiveDateTime)
                                    .foregroundColor(Color.black)
                                //Text(value).colorScheme(.light)
                                Spacer()
                                Text(value.sent.description)
                                    .foregroundColor(Color.black)
                                Spacer()
                                Circle()
                                    .fill(value.sent ? Color.green : Color.red)
                                    .frame(width: 25, height: 25)
                                    .padding(.trailing)
                            }
                            .padding()
                        }
                        Divider()
                    }
                    .background(Color.white)
                }
                .offset(y: refresh.released ? 40 : -10.0)
            })
        }
        .background(Color("ScrollViewBG").ignoresSafeArea())
        
    
//        List(ecg.testID) {data in
//            Text(data.observationTemplate.effectiveDateTime)
//            Spacer()
//            Text(data.sent.description)
//        }
    }
    func updateData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(Animation.linear) {
                if refresh.startOffset == refresh.offset {
                    ecg.readEcgData()
                    refresh.released = false
                    refresh.started = false
                } else {
                    refresh.invalid = true
                }
            }
        }
        print("Updating data")
    }
    func tet() {
        for i in ecg.testID.indices {
            ecg.testID[i].sent = true
        }
    }
    
    func sendData() {
        let url = URL(string: "https://vonk-test-server.azurewebsites.net/Observation")
        guard let requestUrl = url else { fatalError() }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for observation in ecg.testID.indices {
            let postString = ecg.getJSONString(observation: ecg.testID[observation].observationTemplate)
            let data = postString.data(using: .utf8)
            request.httpBody = data
            if ecg.testID[observation].sent {
                print("Continue sendData Loop")
                continue
            }
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        print("Error took place \(error)")
                        return
                    }
             
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            ecg.testID[observation].sent = true
                        }
                        print("Response data string:\n \(dataString)")
                    }
            }
            task.resume()
        }
        for test in ecg.testID {
            print(test.sent)
        }
    }
}

struct Refresh {
    var startOffset : CGFloat = 0
    var offset : CGFloat = 0
    var started : Bool
    var released : Bool
    var invalid : Bool // Scroll
}

struct PullToRefreshView_Previews: PreviewProvider {
    static var previews: some View {
        PullToRefreshView().environment(\.colorScheme, .dark)
    }
}

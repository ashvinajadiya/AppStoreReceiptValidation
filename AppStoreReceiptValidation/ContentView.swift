//
//  ContentView.swift
//  AppStoreReceiptValidation
//
//  Created by Ashvin on 14/10/23.
//

import SwiftUI

struct ContentView: View {
    
    enum EnvironmentName: Int {
        case sandbox
        case production
    }
    

    @State private var selectedEnvironment: Int = 0
    @State private var selectedReceiptSource: Int = 0
    
    @State private var passwordString: String = ""
    @State private var receiptResponse = ""
    @State private var receiptResponseHide = true

    
    var body: some View {
        VStack {
            Text("Apple In-App Receipt Verification")
            
            Picker(selection: $selectedEnvironment.onChange(changeEnvironment), label: Text("Environment").bold()) {
                Text("Sandbox").tag(0)
                Text("Production").tag(1)
            }
            .frame(width: 250)
            
            Picker(selection: $selectedReceiptSource.onChange(changeReceiptSource), label: Text("Receipt From").bold()) {
                Text("App").tag(0)
                Text("File").tag(1)
            }
            .frame(width: 250)
            
            Text("Please check the code & add Receipt data inside file 'Receipt.txt'.")
                .frame(width: 250)
                .foregroundColor(.secondary)
                .isHidden((selectedReceiptSource == 0) ? true : false)
            
            
            TextField("Enter shared secret", text: $passwordString)
                .frame(width: 250)
            
            Button(action: {
                
                if selectedEnvironment == EnvironmentName(rawValue: 0)?.rawValue ?? 0  {
                    // Sandbox
                    print("Let's validate Sandbox receipt")
                } else {
                    // Production
                    print("Let's validate Production receipt")
                }
                
                if selectedReceiptSource == 0  {
                    print("Let's receipt from App")
                } else {
                    print("Let's receipt from File")
                }
                
                // Lets ahead with receipt validation
                validateReceipt()
                
            }, label: {
                Text("Validate")
            })
            
            Group {
                TextEditor(text: $receiptResponse)
                                .foregroundStyle(.blue)
                                .padding(.horizontal)

            }.isHidden(receiptResponseHide)
        }
        .padding()
    }
   
    func changeEnvironment(_ value: Int) {
//    func changeEvnivronment(_ value: EvnivronmentName) {
        selectedEnvironment = value
    }
    
    func changeReceiptSource(_ value: Int) {
//    func changeEvnivronment(_ value: EvnivronmentName) {
        selectedReceiptSource = value
    }
    
    func validateReceipt() {
        
        // Hide File-info message
        receiptResponseHide = true
        
        // Define URL to verify receipt
        var urlString = "https://sandbox.itunes.apple.com/verifyReceipt"
        if selectedEnvironment == EnvironmentName(rawValue: 1)?.rawValue ?? 1  {
            // Production
            urlString = "https://buy.itunes.apple.com/verifyReceipt"
        }
        
        // Get receipt data string
        var receiptString = ""
        if selectedReceiptSource == 0  {
            // Get from App Store Receipt URL
            if let receiptURL = Bundle.main.appStoreReceiptURL  {
                do {
                    receiptString = try Data(contentsOf: receiptURL).base64EncodedString()
                }
                catch {
                    return
                }
            }
        } else {
            // Get from File
            let file = "Receipt"
            guard let url = Bundle.main.url(forResource: "Receipt", withExtension: "txt") else {
                return
            }
            
            if let bundleURL = Bundle.main.url(forResource: file, withExtension: "txt") {
                do {
                    receiptString = try String(contentsOf: bundleURL, encoding: .utf8)
                }
                catch {
                    return
                }
            }
        }
        
        // Prepare Request
        let requestData : [String : Any] = ["receipt-data" : receiptString,
                                            
                                            "password" : passwordString,
                                            
                                            "exclude-old-transactions" : false]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        guard let url = URL(string: urlString) else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        // Send request
        URLSession.shared.dataTask(with: request)  { (data, response, error) in
            
            // Response
            
            // Show File-info message
            receiptResponseHide = false
            do {
                guard let responseData = data else {
                    print("No Response, Error", error?.localizedDescription)
                    receiptResponse = error?.localizedDescription ?? ""
                    return
                }
                
                if let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                    print("Response :", jsonResponse)
                    receiptResponse = jsonResponse.description
                }
               
            } catch let parseError {
                print(parseError)
            }
            
        }.resume()
        
    }
}

#Preview {
    ContentView()
}


   
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: {
                self.wrappedValue
            },
            set: {
                selection in
                self.wrappedValue = selection
                handler(selection)
            })
    }
}


extension View {
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

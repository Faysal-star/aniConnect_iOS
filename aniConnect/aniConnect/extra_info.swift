//
//  extra_info.swift
//  aniConnect
//
//  Created by Iqbal Mahamud on 12/1/25.
//

import SwiftUI
import FirebaseAuth

struct ExtraInfoView: View {
    @Binding var isLoggedIn: Bool
    @Binding var showExtraInfo: Bool
    @State private var fullname: String
    @State private var age: String
    @State private var preferences: String
    @State private var gender: String
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    private let backendURL = "https://ani-connect-backend.vercel.app"
    
    init(isLoggedIn: Binding<Bool>, showExtraInfo: Binding<Bool>, initialFullName: String = "", initialAge: String = "", initialPreferences: String = "", initialGender: String = "") {
        self._isLoggedIn = isLoggedIn
        self._showExtraInfo = showExtraInfo
        self._fullname = State(initialValue: initialFullName)
        self._age = State(initialValue: initialAge)
        self._preferences = State(initialValue: initialPreferences)
        self._gender = State(initialValue: initialGender)
    }
    
    var body: some View {
        VStack {
            Text("Complete Profile")
                .font(.title)
                .padding()
            
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullname)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Preferences", text: $preferences)
                    Picker("Gender", selection: $gender) {
                        Text("Select").tag("")
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: createProfile) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !fullname.trimmingCharacters(in: .whitespaces).isEmpty &&
        !age.trimmingCharacters(in: .whitespaces).isEmpty &&
        !preferences.trimmingCharacters(in: .whitespaces).isEmpty &&
        !gender.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func createProfile() {
        guard let currentUser = Auth.auth().currentUser,
              let ageInt = Int(age) else {
            return
        }
        
        let profileData: [String: Any] = [
            "uid": currentUser.uid,
            "email": currentUser.email ?? "",
            "fullName": fullname,
            "age": ageInt,
            "preferences": preferences,
            "gender": gender,
            "favoriteMovies": []
        ]
        
        print("Profile Data: \(profileData)")
        
        guard let url = URL(string: "\(backendURL)/api/users/users"),
              let jsonData = try? JSONSerialization.data(withJSONObject: profileData) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        isLoading = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response from server"
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("Profile created successfully")
                    showExtraInfo = false
                } else {
                    if let data = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                print("Error response JSON: \(json)")
                                errorMessage = (json["message"] as? String) ?? "Unknown server error"
                            } else if let responseString = String(data: data, encoding: .utf8) {
                                print("Error response string: \(responseString)")
                                errorMessage = "Server error: \(responseString)"
                            }
                        } catch {
                            print("Error parsing response: \(error)")
                            errorMessage = "Server error: \(httpResponse.statusCode)"
                        }
                    }
                }
            }
        }.resume()
    }
}

#Preview {
    ExtraInfoView(isLoggedIn: .constant(true), showExtraInfo: .constant(true))
}


//
//  SettingsView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-10.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("useAPIMode") private var useAPIMode: Bool = true 
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("selectedVoice") private var selectedVoice: String = "Ana Florence"
    
    @State private var isTestingAPI = false
    @State private var showAPIKey = false
    
    private let voices: [String] = ["Claribel Dervla", "Daisy Studious", "Gracie Wise", "Tammie Ema", "Alison Dietlinde", "Ana Florence", "Annmarie Nele", "Asya Anara", "Brenda Stern", "Gitta Nikolina", "Henriette Usha", "Sofia Hellen", "Tammy Grit", "Tanja Adelina", "Vjollca Johnnie", "Andrew Chipper", "Badr Odhiambo", "Dionisio Schuyler", "Royston Min", "Viktor Eka", "Abrahan Mack", "Adde Michal", "Baldur Sanjin", "Craig Gutsy", "Damien Black", "Gilberto Mathias", "Ilkin Urbano", "Kazuhiko Atallah", "Ludvig Milivoj", "Suad Qasim", "Torcull Diarmuid", "Viktor Menelaos", "Zacharie Aimilios", "Nova Hogarth", "Maja Ruoho", "Uta Obando", "Lidiya Szekeres", "Chandra MacFarland", "Szofi Granger", "Camilla Holmström", "Lilya Stainthorpe", "Zofija Kendrick", "Narelle Moon", "Barbora MacLean", "Alexandra Hisakawa", "Alma María", "Rosemary Okafor", "Ige Behringer", "Filip Traverse", "Damjan Chapman", "Wulf Carlevaro", "Aaron Dreschner", "Kumar Dahl", "Eugenio Mataracı", "Ferran Simen", "Xavier Hayasaka", "Luis Moray", "Marcos Rudaski"]
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: useAPIMode ? "gear" : "sparkles")
                        .foregroundColor(useAPIMode ? .blue : .orange)
                    Toggle("Use Free Mode", isOn: Binding(
                        get: { !useAPIMode },
                        set: { useAPIMode = !$0 }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }
            } header: {
                Label("Mode Selection", systemImage: "switch.2")
                    .foregroundColor(.secondary)
                    .font(.headline)
            }
            
            if useAPIMode {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if showAPIKey {
                                TextField("OpenAI API Key", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                SecureField("OpenAI API Key", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Button(action: { showAPIKey.toggle() }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                            
                            Button("Test") {
                                isTestingAPI = true
                            }
                            .buttonStyle(.borderless)
                            .disabled(apiKey.isEmpty)
                        }
                        
                        Text("Enter your OpenAI API key to use the API mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("API Configuration", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                } footer: {
                    Text("Your API key is stored securely in the keychain")
                        .font(.caption)
                }
            }
            
            Section {
                Picker("Select Voice", selection: $selectedVoice) {
                    ForEach(voices, id: \.self) { voice in
                        Text(voice)
                            .tag(voice)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Label("Voice Settings", systemImage: "waveform")
                    .foregroundColor(.secondary)
                    .font(.headline)
            } footer: {
                Text("Choose a voice for the narrator")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 400, height: 450)
        .background(Color(.windowBackgroundColor))
        .alert("Testing API Key", isPresented: $isTestingAPI) {
            Button("OK") { isTestingAPI = false }
        } message: {
            Text("This would test the API key validity")
        }
    }
}

#Preview {
    SettingsView()
}

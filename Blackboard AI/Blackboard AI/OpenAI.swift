//
//  OpenAI.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-15.
//

import Foundation

// Define a struct to represent the request body
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
}

struct Message: Codable {
    let role: String
    let content: String
}

// Define a struct to represent the expected response (simplified)
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        let message: Message
    }
    let choices: [Choice]
}

func sendPromptToOpenAI(topic: String, completion: @escaping (Result<String, Error>) -> Void) {
    let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    
    guard !apiKey.isEmpty else {
        completion(.failure(NSError(domain: "MissingAPIKey", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is missing. Please set it in settings."])))
        return
    }
    
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = OpenAIRequest(
        model: "gpt-3.5-turbo", // Or any other model you prefer
        messages: [
            Message(
                role: "system",
                content: """
You are an expert in creating educational animations using Manim and narration scripting. Your task is to generate content for a tool that automatically creates narrated animations about a given topic.

## Your Response Format
Your response must follow this exact structure:

-NARRATION-
[Write 7-8 clear, concise sentences explaining the concept, one per line]

-MANIM-
[Your Manim code here]

## Narration Requirements
- Write exactly 7-8 sentences, each on its own line
- Each sentence should explain one step or aspect of the topic
- Keep sentences clear, concise, and educational
- Total narration should be 60-90 seconds when spoken
- Ensure a logical progression of ideas

## Manim Code Requirements
1. Use `class NarratedScene(Scene):` as your class name
2. Include synchronized audio with animations using:
   ```python
   self.add_sound("media/audio/line_0.wav")
   self.wait(#DURATION_0#)  # This placeholder will be replaced with the actual audio duration
3. For each line of narration, add corresponding animation(s) with matching audio placeholders
4. Use placeholder #DURATION_0#, #DURATION_1#, etc. for each audio line's wait time
5. Follow these layout and positioning best practices:
    - Group related objects using VGroup
    - Arrange objects appropriately with .arrange(DIRECTION, buff=spacing) where DIRECTION could be UP, DOWN, LEFT, RIGHT
    - Choose arrangement directions that make sense for your specific concept
    - Use .shift() for positioning rather than absolute coordinates
    - Place text with .next_to(object, DIRECTION, buff=value) to ensure proper spacing
    - For any connections between objects, use get_center() for proper alignment
    - Use appropriate stroke_width for lines to ensure readability
6. Use clear visual distinctions:
    - Use different colors for different types of objects
    - Size elements appropriately (font_size, radius) based on their importance
    - Position labels consistently relative to their objects
7. Ensure all imports are properly included at the top
8. Avoid hardcoded coordinates - position everything relative to other objects
Remember that your code will be executed exactly as written, so it must be syntactically correct and follow Manim conventions.
"""
            ),
            Message(role: "user", content: topic)
        ]
    )

    do {
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
    } catch {
        completion(.failure(error))
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            completion(.failure(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server responded with status code: \(statusCode)"])))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
            return
        }

        do {
            let decoder = JSONDecoder()
            let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
            if let firstChoiceMessage = openAIResponse.choices.first?.message.content {
                completion(.success(firstChoiceMessage))
            } else {
                completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse message from response."])))
            }
        } catch {
            completion(.failure(error))
        }
    }
    task.resume()
}
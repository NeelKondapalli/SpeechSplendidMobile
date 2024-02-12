import Foundation

struct OpenAIResponseHandler {
    func decodeJson(jsonString: String) -> OpenAIResponse? {
        let json = jsonString.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        do {
            let product = try decoder.decode(OpenAIResponse.self, from: json)
            return product
            
        } catch {
            print("Error decoding OpenAI API Response")
        }
        
        return nil
    }
}

//struct OpenAIResponse: Codable {
//    var id: String
//    var object: String
//    var created: Int
//    var model: String
//    var choices: [Choice]
//}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }

    let choices: [Choice]
}

struct Choice: Codable {
    var text: String
    var index: Int
    var logprobs: String?
    var finish_reason: String
}

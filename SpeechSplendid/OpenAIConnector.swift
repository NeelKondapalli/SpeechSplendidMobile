
import Foundation

public class OpenAIConnector {
    // MARK: - IMPORTANT STUFF TO READ
    /// Follow along with the article and fill out these two.
    /// If you're building for MacOS, head to the target using this file, Signing & Capabilities, App Sandbox, and enable Outgoing Connections (Client). This lets your app connect to the OpenAI Servers.
    //let openAIURL: URL? = URL(string: "https://api.openai.com/v1/engines/text-davinci-002/completions")
    let openAIURL: URL? = URL(string: "https://api.openai.com/v1/chat/completions")
    
    var openAIKey: String? = ""
    
    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String

        // Check if the key is not nil and not empty
        if let testkey = key, !testkey.isEmpty {
            // The key is valid, you can use it here
            self.openAIKey = testkey
        } else {
            // Handle the case where the key is missing or empty
            print("API key does not exist or is empty")
        }
    }
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) -> Data? {
    
        let semaphore = DispatchSemaphore(value: 0)
        let session: URLSession
        if (sessionConfig != nil) {
            session = URLSession(configuration: sessionConfig!)
        } else {
            session = URLSession.shared
        }
        var requestData: Data?
        let task = session.dataTask(with: request as URLRequest, completionHandler:{ (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error != nil {
                print("error: \(error!.localizedDescription): \(error!.localizedDescription)")
            } else if data != nil {
                requestData = data
            }
            
            print("Semaphore signalled")
            semaphore.signal()
        })
        task.resume()
        
        // Handle async with semaphores. Max wait of 10 seconds
        let timeout = DispatchTime.now() + .seconds(20)
        print("Waiting for semaphore signal")
        let retVal = semaphore.wait(timeout: timeout)
        print("Done waiting, obtained - \(retVal)")
        return requestData
    }
    
    //    public func processPrompt(prompt: String, maxTokens: Int, minTokens: Int) -> Optional<String> {
    //        /// cURL stuff.
    //        var request = URLRequest(url: self.openAIURL!)
    //        request.httpMethod = "POST"
    //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    //        request.addValue("Bearer \(self.openAIKey)", forHTTPHeaderField: "Authorization")
    //
    //        let httpBody: [String: Any] = [
    //            "prompt" : prompt,
    //            /// Adjust this to control the maxiumum amount of tokens OpenAI can respond with.
    //            "max_tokens" : maxTokens,
    //            /// You can add more parameters below, but make sure they match the ones in the OpenAI API Reference.
    //        ]
    //
    //        var httpBodyJson: Data
    //
    //        do {
    //            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
    //        } catch {
    //            print("Unable to convert to JSON \(error)")
    //            return nil
    //        }
    //
    //        request.httpBody = httpBodyJson
    //        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
    //            let jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
    //            print(jsonStr)
    //            /// I know there's an error below, but we'll fix it later on in the article, so make sure not to change anything
    //            let responseHandler = OpenAIResponseHandler()
    //
    //            return responseHandler.decodeJson(jsonString: jsonStr)?.choices[0].text
    //
    //        }
    //
    //        return nil
    //    }
    
    
    
    public func processPrompt(prompt: String, maxTokens: Int, minTokens: Int) async throws -> String? {
    
        
        guard let openAIURL = openAIURL, let openAIKey = openAIKey else {
            return nil
        }
        
        var request = URLRequest(url: openAIURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
//        let httpBody: [String: Any] = [
//            "prompt": prompt,
//            "max_tokens": maxTokens
//        ]
        let httpBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are an analytical speech coach. Provide constructive feedback on how the user can improve their speech."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: httpBody)
            if let requestData = executeRequest(request: request, withSessionConfig: nil) {
                let jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                print(jsonStr)
                /// I know there's an error below, but we'll fix it later on in the article, so make sure not to change anything
                let responseHandler = OpenAIResponseHandler()
                
                //return responseHandler.decodeJson(jsonString: jsonStr)?.choices[0].text
                if let response = responseHandler.decodeJson(jsonString: jsonStr) {
                    return response.choices.first?.message.content
                } else {
                    // Handle error or nil case
                    return nil
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
}

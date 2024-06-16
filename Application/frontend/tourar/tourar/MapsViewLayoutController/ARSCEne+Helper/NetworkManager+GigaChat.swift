//
//  NetworkManager+GigaChat.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation

var lastGenerateMessage = ""

let RgUID = "07f0892f-403d-410b-b4e4-516c50e21e10"
let authBasic = "MDdmMDg5MmYtNDAzZC00MTBiLWI0ZTQtNTE2YzUwZTIxZTEwOjhkMzYyNDc0LTQ2ZjgtNGYzMy1hMzcxLTk0NTI0YTU1NDVlZg=="
func getTokenToGigaChat(requestString : String ){
    let url = URL(string: "https://ngw.devices.sberbank.ru:9443/api/v2/oauth")!
    let payload = "scope=GIGACHAT_API_PERS"
    let headers: [String: String] = [
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
        "RqUID": "\(RgUID)",
        "Authorization": "Basic \(authBasic)"
    ]

    var request = URLRequest(url: url)
    request.httpBody = payload.data(using: .utf8)
    request.allHTTPHeaderFields = headers
    request.httpMethod = "POST"

    let session = URLSession.shared
    session.dataTask(with: request) { (data, response, error) in
        guard let data = data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                let token = json["access_token"] as? String
                if ( token != nil ) {
                    sendPostRequestToChat(tokenGiga : token!, textToGiga : requestString )
                }
                print(json)
            }
        } catch let parseError {
            print("Error serializing json: \(parseError)")
        }
    }.resume()
}
func sendPostRequestToChat( tokenGiga : String, textToGiga : String )
{
    let url = URL(string: "https://gigachat.devices.sberbank.ru/api/v1/chat/completions")!
    let payload = ["model": "GigaChat", "messages": [["role": "user", "content": "\(textToGiga)"]], "temperature": 1, "top_p": 0.1, "n": 1, "stream": false, "max_tokens": 512, "repetition_penalty": 1] as [String : Any]

    var request = URLRequest(url: url)
    request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(tokenGiga)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"

    let session = URLSession.shared
    session.dataTask(with: request) { (data, response, error) in
        guard let data = data else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            print(json)
            let responGiga = json["choices"] as? [[String : Any]]
            if ( responGiga != nil )
            {
                for itemRespoGiga in responGiga!
                {
                    let messageArray = itemRespoGiga["message"] as? [String:Any]
                    if ( messageArray != nil )
                    {
                        let contentResponse = messageArray!["content"] as? String
                        if ( contentResponse != nil )
                        {
                            if ( lastGenerateMessage != contentResponse!)
                            {
                                voiceHelperUI(textSpeech: "\(contentResponse!)")
                                lastGenerateMessage = contentResponse!
                            }
                        }
                    }
                }
            }
        } catch let parseError {
            print("Error serializing json: \(parseError)")
        }
    }.resume()

}

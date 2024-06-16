//
//  FetchDataFromServer+Helper.swift
//  tourar
//
//  Created by Артем Стратиенко on 15.06.2024.
//
import Foundation
import YandexMapsMobile


struct Coordinate {
    var latitude : Double
    var longitude : Double
}
struct PoiLocalInfo{
    var uuid : String
    var namePoi : String
    var descriptionPoi : String
    var location : Coordinate
}
struct AudioObjectPoi{
    var uuid : String
    var uuidPoiParent : String
    var duration : Int
    var type : String
}

struct ImageObjectPoi{
    var uuid : String
    var uuidPoiParent : String
    var type : String
}

let api_key = "7c6c2db9-d237-4411-aa0e-f89125312494"

var poiPointArray : [YMKPoint]  = []

var isConnected = false


func checkServerConnection(ip_server : String)
{
    let urlApi = "\(ip_server)"
    guard let url = URL(string: urlApi)
    else
    {
        print("Failed URL_checkServerConnection : \(urlApi)")
        return
    }
    print("URLSession :: Start")
    let session = URLSession.shared
    session.dataTask(with: url) { (data,response,error) in
        if let response = response {
            print("Response_checkServerConnection:\(response)")
            if let response = response as? HTTPURLResponse {
                print("statusCode: \(response.statusCode)")
                if ( response.statusCode == 200 )
                {
                    isConnected = true

                }
                else
                {
                    isConnected = false

                }
            }
        }
        if let error = error {
            print("Error__checkServerConnection:\(error)")
            isConnected = false
        }
    }.resume()
    print("Load DATA_checkServerConnection :: Finish")
}
func fetchAllDataPoint(cityName : String)
{
    print("Load DATA_fetchAllData :: Start")
    let urlApi = "https://api.izi.travel/mtg/objects/search?languages=ru&includes=all&query=\(cityName)&api_key=\(api_key)"
    print("stringUrl\(urlApi)")
    guard let url = URL(string: urlApi)
    else
    {
        print("Failed URL_fetchAllData : \(urlApi)")
        return
    }
    print("URLSession :: Start")
    let session = URLSession.shared
    session.dataTask(with: url) { (data,response,error) in
        if let response = response {
            print("Response_fetchAllData:\(response)")
        }
        if let error = error {
            print("Error__fetchAllData:\(error)")
        }
        guard let data = data else {return}
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let preload = json as! [[String:Any]]
            print("JSON ARRAY_COUNT : \(preload.count)")
            print(preload)
            for itemJson in preload
            {
                let typePoi = itemJson["type"] as? String
                if ( typePoi != nil )
                {
                    if ( typePoi! != "museum")
                    {
                        let categoryPoi = itemJson["category"] as? String
                        if ( categoryPoi != nil )
                        {
                            if ( categoryPoi == "walk")
                            {
                                fetchObjectPoi(uuid: itemJson["uuid"] as! String)
                            }
                        }
                    }
                }
            }
        } catch {
        print(error)
        }
        //
    }.resume()
    print("Load DATA_fetchAllData :: Finish")
}
func fetchObjectPoi(uuid : String)
{
    let urlApi = "https://api.izi.travel/mtgobjects/\(uuid)?languages=ru,en&includes=all&except=translations,publisher,download&api_key=\(api_key)"
    print("stringUrl\(urlApi)")
    guard let url = URL(string: urlApi)
    else
    {
        print("Failed URL_fetchObjectPoi : \(urlApi)")
        return
    }
    print("URLSession_fetchObjectPoi :: Start")
    let session = URLSession.shared
    session.dataTask(with: url) { (data,response,error) in
        if let response = response {
            print("Response_fetchObjectPoi:\(response)")
        }
        if let error = error {
            print("Error__fetchObjectPoi:\(error)")
        }
        guard let data = data else {return}
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let preload = json as! [[String:Any]]
            for itemJson in preload
            {
                let objPoiArray = itemJson["content"] as? [[String:Any]]
                for objP in objPoiArray!
                {
                    let childObjPoiUUID = objP["children"] as? [[String:Any]]
                    if ( childObjPoiUUID != nil)
                    {
                        for objUUIDPointPoi in childObjPoiUUID!
                        {
                            // get uuid
                            fetchGetLocalPoi(uuid: objUUIDPointPoi["uuid"] as! String)
                        }
                    }
                }
            }
            
        } catch {
        print(error)
        }
        //
    }.resume()
    print("Load DATA_fetchObjectPoi :: Finish")
}
func fetchGetLocalPoi(uuid : String)
{
    let urlApi = "https://api.izi.travel/mtgobjects/\(uuid)?languages=ru,en&includes=all&except=translations,publisher,download&api_key=\(api_key)"
    guard let url = URL(string: urlApi)
    else
    {
        print("Failed URL_fetchLocalPoi : \(urlApi)")
        return
    }
    print("URLSession_fetchLocalPoi :: Start")
    let session = URLSession.shared
    session.dataTask(with: url) { (data,response,error) in
        if let response = response {
            print("Response_fetchLocalPoi:\(response)")
        }
        if let error = error {
            print("Error__fetchLocalPoi:\(error)")
        }
        guard let data = data else {return}
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let preload = json as? [[String:Any]]
            for itemJson in preload!
            {
                let contentUUIDJSON = itemJson["content_provider"] as? [String:Any]
                let uuidProvide = contentUUIDJSON!["uuid"] as? String
                let objPoiArray = itemJson["content"] as! [[String:Any]]
                // insert position poi to array
                let locationObj = itemJson["location"] as? [String:Any]
                if ( locationObj != nil )
                {
                    let lat = locationObj!["latitude"] as? Double
                    let lon = locationObj!["longitude"] as? Double
                   
                    if ( lat != nil && lon != nil )
                    {
                        poiPointArray.append(YMKPoint(latitude: lat!, longitude: lon!))
                    }
                }
                // load source info
                for objP in objPoiArray
                {
                    // fetch audi [array]
                    let audioUUID = objP["audio"] as? [[String:Any]]
                    if ( audioUUID != nil )
                    {
                        for objAudioUUID in audioUUID!
                        {
                            let getAudioObj = objAudioUUID["uuid"] as? String
                            fetchAudioGuidePoiLocal(uuidProvide: uuidProvide!, uuidAudio: getAudioObj!)
                        }
                    }
                    // fetch image [array]
                    let imageUUID = objP["images"] as? [[String:Any]]
                    if ( imageUUID != nil)
                    {
                        for objImageUUID in imageUUID!
                        {
                            let getImageObj = objImageUUID["uuid"] as? String
                            fetchImagePoiLocal(uuidProvide: uuidProvide!, uuidImage: getImageObj!)
                        }
                    }
                }
            }
        } catch {
        print(error)
        }
        //
    }.resume()
    print("Load DATA_fetchLocalPoi :: Finish")
}

func fetchAudioGuidePoiLocal( uuidProvide : String, uuidAudio : String)
{
    
}
func fetchImagePoiLocal( uuidProvide : String, uuidImage : String)
{
    
}

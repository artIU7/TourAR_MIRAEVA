//
//  FetchDataFromServer+Helper.swift
//  tourar
//
//  Created by Артем Стратиенко on 15.06.2024.
//
import Foundation
import YandexMapsMobile
import AVFoundation


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

var fetchDataLocationPoi    : [String : YMKPoint]  = [:]
var fetchDataDescriptionPoi : [String : String  ]  = [:]
var fetchDataTitlePoi       : [String : String  ]  = [:]
var fetchDataImagesPoi      : [String : UIImage ]  = [:]
var fetchDataAudioPoi       : [String : AVAsset ]  = [:]
//var fetchDataAudioPoi       : [String : ]
var isConnected = false

var sessionServerConnection = URLSession()
var sessionLoadFullData     = URLSession()
var sessionLoadObjectPoi    = URLSession()
var sessionLoadLocalPoint   = URLSession()
var sessionLoadImage        = URLSession()
var sessionLoadAudio        = URLSession()

//
var isSuspendSessionLoadFullData = false
var isSuspendSessionLoadObjectPoi  = false
var isSuspendsessionLoadLocalPoint = false
var isSuspendSessionLoadImage = false
var isSuspendSessionLoadAudio = false

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
    sessionServerConnection = URLSession.shared
    sessionServerConnection.dataTask(with: url) { (data,response,error) in
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
    sessionLoadFullData = URLSession.shared
    sessionLoadFullData.dataTask(with: url) { (data,response,error) in
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
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    fetchObjectPoi(uuid: itemJson["uuid"] as! String)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
        print(error)
        }
    }.resume()
    print("Load DATA_fetchAllData :: Finish")
    if ( sessionLoadFullData.dataTask(with: url).state != .canceling && sessionLoadFullData.dataTask(with: url).state != .running)
    {
        isSuspendSessionLoadFullData = true
    }
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
    sessionLoadObjectPoi = URLSession.shared
    sessionLoadObjectPoi.dataTask(with: url) { (data,response,error) in
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
    }.resume()
   
    print("Load DATA_fetchObjectPoi :: Finish")
    if ( sessionLoadObjectPoi.dataTask(with: url).state != .canceling && sessionLoadObjectPoi.dataTask(with: url).state != .running)
    {
        isSuspendSessionLoadObjectPoi = true
    }
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
    sessionLoadLocalPoint = URLSession.shared
    sessionLoadLocalPoint.dataTask(with: url) { (data,response,error) in
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
                let uuidItem        = itemJson["uuid"] as? String
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
                        if ( uuidItem != nil )
                        {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                fetchDataLocationPoi[uuidItem!] = YMKPoint(latitude: lat!, longitude: lon!)
                            }
                        }
                    }
                }
                // load source info after content preload
                for objP in objPoiArray
                {
                    // fetch audi [array]
                    let audioUUID = objP["audio"] as? [[String:Any]]
                    if ( audioUUID != nil )
                    {
                        for objAudioUUID in audioUUID!
                        {
                            let getAudioObj = objAudioUUID["uuid"] as? String
                            fetchAudioGuidePoiLocal(uuid : uuidItem!, uuidProvide: uuidProvide!, uuidAudio: getAudioObj!)
                        }
                    }
                    // fetch image [array]
                    let imageUUID = objP["images"] as? [[String:Any]]
                    if ( imageUUID != nil)
                    {
                        for objImageUUID in imageUUID!
                        {
                            let getImageObj = objImageUUID["uuid"] as? String
                            fetchImagePoiLocal(uuid : uuidItem!,uuidProvide: uuidProvide!, uuidImage: getImageObj!)
                        }
                    }
                    // fetch title:
                    let title = objP["title"] as? String
                    if ( title != nil )
                    {
                        if ( uuidItem != nil )
                        {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                fetchDataTitlePoi[uuidItem!] = title
                            }
                        }
                    }
                    // fetch desc:
                    let description = objP["desc"] as? String
                    if ( description != nil )
                    {
                        if ( uuidItem != nil )
                        {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                fetchDataDescriptionPoi[uuidItem!] = description
                            }
                        }
                    }
                }
            }
        } catch {
        print(error)
        }
    }.resume()
    print("Load DATA_fetchLocalPoi :: Finish")
    if ( sessionLoadLocalPoint.dataTask(with: url).state != .canceling && sessionLoadLocalPoint.dataTask(with: url).state != .running)
    {
        isSuspendsessionLoadLocalPoint = true
    }
}

func fetchAudioGuidePoiLocal( uuid : String, uuidProvide : String, uuidAudio : String)
{
    let urlApi = "https://media.izi.travel/\(uuidProvide)/\(uuidAudio).m4a?api_key=\(api_key)"
    guard let url = URL(string: urlApi)
    else
    {
        print("Failed URL_fetchLocalPoi : \(urlApi)")
        return
    }
    //
    let audioPoi = AVAsset(url: url)
    if ( audioPoi != nil )
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            fetchDataAudioPoi[uuid] = audioPoi
        }
    }
    // dataTask loop
    sessionLoadAudio = URLSession.shared
    sessionLoadAudio.dataTask(with: url) { (data,response,error) in
        if let response = response {
            print("Response_fetchObjectPoi:\(response)")
        }
        if let error = error {
            print("Error__fetchObjectPoi:\(error)")
        }
        guard let data = data else {return}
       
        //
    }.resume()
    print("URLSession_fetchLocalPoi :: Finiosh")
    if ( sessionLoadAudio.dataTask(with: url).state != .canceling && sessionLoadAudio.dataTask(with: url).state != .running)
    {
        isSuspendSessionLoadAudio = true
    }
    print("URLSession_fetchLocalPoi :: Start")
}
func fetchImagePoiLocal( uuid : String, uuidProvide : String, uuidImage : String)
{
    let urlApi = "https://media.izi.travel/\(uuidProvide)/\(uuidImage)_800x600.jpg?api_key=\(api_key)"
    guard let url = URL(string: urlApi)
    else
    {
        print("Failed URL_fetchLocalPoi : \(urlApi)")
        return
    }
    // dataTask loop
    sessionLoadImage = URLSession.shared
    sessionLoadImage.dataTask(with: url) { (data,response,error) in
        if let response = response {
            print("Response_fetchObjectPoi:\(response)")
        }
        if let error = error {
            print("Error__fetchObjectPoi:\(error)")
        }
        guard let data = data else {return}
        let imagePoi = UIImage(data: data)
        if ( imagePoi != nil )
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                fetchDataImagesPoi[uuid] = imagePoi
            }
        }
        //
    }.resume()
    print("URLSession_fetchLocalPoi :: Finiosh")
    if ( sessionLoadImage.dataTask(with: url).state != .canceling && sessionLoadImage.dataTask(with: url).state != .running)
    {
        isSuspendSessionLoadImage = true
    }
}
func stateSessionComplete()->Bool
{
    if ( isSuspendsessionLoadLocalPoint && isSuspendSessionLoadImage && isSuspendSessionLoadFullData && isSuspendSessionLoadObjectPoi && isSuspendSessionLoadAudio )
    {
        return true
    }
    else
    {
        return false
    }
}

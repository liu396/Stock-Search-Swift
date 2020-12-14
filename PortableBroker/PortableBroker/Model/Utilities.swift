//
//  Functions.swift
//  StockSearch
//
//  Created by liuchang on 11/18/20.
//

import Foundation
import Alamofire
import SwiftyJSON


public class Debouncer{
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    public init(delay: TimeInterval){
        self.delay = delay
    }
    
    public func run(action: @escaping () -> Void){
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
}


public func getJSON (url: String, callback: @escaping (_ json: JSON) -> Void){
    if let url = URL(string: (url)) {
        print("requesting: \(url)")
        AF.request(url).validate().responseJSON{ response in
            if let data = response.data {
                let json = JSON(data)
                callback(json)
                return
            }
        }
    }
}

class AutoCandidate: Identifiable{
    var ticker: String
    var name: String
    init(ticker: String, name: String){
        self.ticker = ticker
        self.name = name
    }
}

class DailyPrice {
    var ticker: String
    var lastPrice: Float
    var prevClose: Float
    init(ticker: String, lastPrice: Float, preClose: Float){
        self.ticker = ticker
        self.lastPrice = lastPrice
        self.prevClose = preClose
    }
}

struct Stock: Hashable & Codable {
    var ticker: String
    var name: String
    var avgPrice: Float
    var share: Float
}

struct FavoriteStock: Hashable & Codable{
    var ticker: String
    var name: String
}

struct News: Hashable{
    var date: String
    var url: String
    var title: String
    var urlToImage: String
    var sourceName: String
    var author: String
}

//struct Stock: Hashable & Codable{
//    var ticker: String
//    var name: String
//}


let urlPrefix = "https://price-inquiry-ios.wl.r.appspot.com/"
let urlAutoCompelete = urlPrefix + "autocomplete/"
let urlLastPrice = urlPrefix + "lastprice/"
let urlSummary = urlPrefix + "summary/"
let urlNews = urlPrefix + "news/"

let encoder = JSONEncoder()
let decoder = JSONDecoder()



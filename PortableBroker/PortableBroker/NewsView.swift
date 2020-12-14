//
//  NewsView.swift
//  StockSearch
//
//  Created by liuchang on 11/28/20.
//

import SwiftUI
import KingfisherSwiftUI
import SwiftyJSON

struct NewsView: View {
    @State var newsData: [News] = []
    @State var midDate: String = ""
    
    var ticker: String
    
    private func getNews(ticker: String) -> Void{
        let url = urlNews + ticker
        var temp:[News] = []
//        print("news url: ", url)
        getJSON(url: url, callback: {json in
            let data = json.arrayValue
//            print("data:", data)
            for item in data{
                let isoDate = item["publishedAt"].stringValue
//                print("isoDate:",isoDate)
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let date = dateFormatter.date(from:isoDate)!
                let now = Date()
                let diffMins = Calendar.current.dateComponents([.minute], from: date, to: now)
                let numMins = diffMins.minute
                if (numMins! < 60){
                    self.midDate = String(numMins!) + " minutes ago"
                }
                else{
                    let diffHours = Calendar.current.dateComponents([.hour], from: date, to: now)
                    let numHours = diffHours.hour
                    if (numHours! < 24){
                        self.midDate = String(numHours!) + "h ago"
                    }
                    else {
                        let diffDays = Calendar.current.dateComponents([.day], from: date, to: now)
                        let numDays = diffDays.day
                        self.midDate = String(numDays!) + " days ago"
                    }
                }
//                print(item["urlToImage"].stringValue)
                self.newsData.append(News(date:midDate,url:item["url"].stringValue, title: item["title"].stringValue,urlToImage: item["urlToImage"].stringValue, sourceName: item["source"]["name"].stringValue,author: item["author"].stringValue))
//                print("midDate:",midDate)
                temp.append(News(date:midDate,url:item["url"].stringValue, title: item["title"].stringValue,urlToImage: item["urlToImage"].stringValue, sourceName: item["source"]["name"].stringValue,author: item["author"].stringValue))
//                print("midDate:",midDate)
            }
//            print("temp", temp.count)
        })
    }
    
    var body: some View {
        HStack{
            Text("News").font(.title).frame(height: 30)
            Spacer()
        }.onAppear{getNews(ticker: ticker)}
        if (newsData.count != 0){
            HStack {
                VStack(alignment: .leading){
                    let url0 = URL(string: newsData[0].urlToImage)
                    HStack {
                        KFImage(url0).resizable()
                            .frame(height: 180, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    HStack {
                        VStack(alignment: .leading){
                            HStack {
                                Text(newsData[0].sourceName + "   " + newsData[0].date).font(.footnote).foregroundColor(.gray).padding(.vertical, 1)
                            }
                            HStack {
                                Text(newsData[0].title).font(.headline).fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                            }.frame(maxHeight:.infinity)
                        }
                    }
                }.frame(maxHeight:.infinity)
            }.background(Color.white)
//            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contextMenu {
                Button(action: {
                    guard let google = URL(string: newsData[0].url),
                         UIApplication.shared.canOpenURL(google) else {
                         return
                     }
                     UIApplication.shared.open(google,
                                               options: [:],
                                               completionHandler: nil)
                }) {
                    Text("Open in Safari")
                    Image(systemName: "safari")
                }
                Button(action: {
                    let urlTwitter = "https://twitter.com/intent/tweet?text="+"Check%20out%20this%20link:"+"&url="+String(newsData[0].url)+"&hashtags=CSCI571StockApp"
                    guard let twitter = URL(string: urlTwitter),
                         UIApplication.shared.canOpenURL(twitter) else {
                         return
                     }
                     UIApplication.shared.open(twitter,
                                               options: [:],
                                               completionHandler: nil)
                }) {
                    Text("Share on Twitter")
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .onTapGesture{
                guard let google = URL(string: newsData[0].url),
                     UIApplication.shared.canOpenURL(google) else {
                     return
                 }
                 UIApplication.shared.open(google,
                                           options: [:],
                                           completionHandler: nil)
            }
            Divider()
            ForEach(1..<newsData.count){i in
                let url = URL(
                    string: newsData[i].urlToImage
                )
                HStack{
                    VStack(alignment: .leading){
                        Text(newsData[i].sourceName + "   " + newsData[i].date).font(.system(size: 12)).foregroundColor(.gray).padding(.vertical, 1)
                        Text(newsData[i].title).font(.system(size: 14, weight: .bold)).lineLimit(3).foregroundColor(.black).padding(.vertical, 2)
                    }.frame(minHeight: 90, maxHeight: .infinity)
                    Spacer()
                    KFImage(url).resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }.frame(maxHeight: .infinity)
                .lineLimit(100)
                .background(Color.white)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contextMenu {
                    Button(action: {
                        guard let google = URL(string: newsData[i].url),
                             UIApplication.shared.canOpenURL(google) else {
                             return
                         }
                         UIApplication.shared.open(google,
                                                   options: [:],
                                                   completionHandler: nil)
                    }) {
                        Text("Open in Safari")
                        Image(systemName: "safari")
                    }
                    Button(action: {
                        let urlTwitter = "https://twitter.com/intent/tweet?text="+"Check%20out%20this%20link:"+"&url="+String(newsData[i].url)+"&hashtags=CSCI571StockApp"
                        guard let twitter = URL(string: urlTwitter),
                             UIApplication.shared.canOpenURL(twitter) else {
                             return
                         }
                         UIApplication.shared.open(twitter,
                                                   options: [:],
                                                   completionHandler: nil)
                    }) {
                        Text("Share on Twitter")
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .onTapGesture{
                    guard let google = URL(string: newsData[i].url),
                         UIApplication.shared.canOpenURL(google) else {
                         return
                     }
                     UIApplication.shared.open(google,
                                               options: [:],
                                               completionHandler: nil)
                 }
            }
        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView(ticker: "aapl")
    }
}


//
//  DetailView.swift
//  StockSearch
//
//  Created by liuchang on 11/19/20.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var title: String
    var url: URL
    var loadStatusChanged: ((Bool, Error?) -> Void)? = nil

    func makeCoordinator() -> WebView.Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // you can access environment via context.environment here
        // Note that this method will be called A LOT
    }

    func onLoadStatusChanged(perform: ((Bool, Error?) -> Void)?) -> some View {
        var copy = self
        copy.loadStatusChanged = perform
        return copy
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.loadStatusChanged?(true, nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.title = webView.title ?? ""
            parent.loadStatusChanged?(false, nil)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loadStatusChanged?(false, error)
        }
    }
}

struct DetailView: View {
    
    @AppStorage ("savedStocks") var savedStocks: String?
    @AppStorage ("avaliableMoney") var money: String?
    @AppStorage ("favoriteStocks") var favoriteStocks: String?
    
    var ticker: String
    var name: String
    
    @State var repeating: Timer?
    @State var change: Float = 0.0
    @State var price: Float = 0.0
    @State var lowPrice: Float = 0.0
    @State var highPrice: Float = 0.0
    @State var volume: Int = 0
    @State var mid: Float = 0.0
    @State var bid: Float = 0.0
    @State var openPrice: Float = 0.0
    @State var showPrice =  false
    @State var indexInList: Int?
    @State var indexInFavorite: Int?
    @State var showHistory = true
    @State var description = ""
    @State var showMore = false
    @State var showToast = false
    @State var showTradeToast = false
    @State var infoToShow = ""
    @State var showTradeView = false
    @State var showCongrats = false
    @State var numToBuy = ""
    @State var buyOrSell = "bought"
    @State var title: String = ""
    @State var error: Error? = nil
    
    @State var listStocks: [Stock] = []
    @State var listFavorites: [FavoriteStock] = []
    
    private func loadPortfolio() -> Void{
        print("loading Portfolio...")
        if savedStocks == nil{
            listStocks = []
        }
        else{
            let json = savedStocks!.data(using: . utf8)!
            let product: [Stock]
            do {
                product = try decoder.decode([Stock].self,from: json)
            }
            catch{
                product = []
            }
            listStocks = product
        }
        let count = listStocks.count
        if count == 0 {
            print("No item in portfolio")
            return
        }
        
        for index in 0..<count{
            if listStocks[index].ticker.uppercased() == ticker{
                indexInList = index
                print("Ticker is in portfolio")
                break
            }
        }
        print("Stock portfolio got")
        print(listStocks)
    }
    
    private func loadFavorite() -> Void{
        print("loading Favorites...")
        if favoriteStocks == nil{
            listFavorites = []
        }
        else{
            let json = favoriteStocks!.data(using: .utf8)!
            let product: [FavoriteStock]
            do{
                product = try decoder.decode([FavoriteStock].self,from: json)
            }
            catch{
                product = []
            }
            listFavorites = product
        }
        let count = listFavorites.count
        if count == 0{
            print("No item in favorite")
            return
        }
        
        
        for index in 0..<count{
            if listFavorites[index].ticker.uppercased() == ticker{
                indexInFavorite = index
                print("Ticker is in favorite")
                break
            }
        }
        print("Favorite Stocks got")
        print(listFavorites)
    }
    
    private func encodePortfolio() -> Void{
        print("Encoding portfoilio...")
        let data: Data?
        do{
            data = try encoder.encode(listStocks)
            savedStocks = String(data:data!, encoding: .utf8)!
        }
        catch{
            data = nil
        }
        print("Encoding portfolio finished")
    }
    
    private func encodeFavorite() -> Void{
        print("Encoding favorites...")
        let data: Data?
        do{
            data = try encoder.encode(listFavorites)
            favoriteStocks = String(data:data!, encoding: .utf8)!
        }
        catch{
            data = nil
        }
        print("Encoding storage finished")
    }
    
    
    private func singleUpdate(ticker: String){
        let url = urlLastPrice + ticker
        getJSON(url: url, callback: {json in
            let data = json.arrayValue[0]
            self.price = data["last"].floatValue
            self.change = price - data["prevClose"].floatValue
            self.mid = data["mid"].floatValue
            self.openPrice = data["open"].floatValue
            self.bid = data["bidPrice"].floatValue
            self.lowPrice = data["low"].floatValue
            self.highPrice = data["high"].floatValue
            self.volume = data["volume"].intValue
            showPrice  = true
        })
    }
    
    private func getDescription(ticker: String){
        let url = urlSummary + ticker
        getJSON(url:url, callback: {json in
            self.description = json["description"].stringValue
        })
    }
    
    
    var addButton: some View{
        Button(action: {
            if indexInFavorite == nil{
                listFavorites.append(FavoriteStock(ticker:ticker,name:name))
                indexInFavorite = listFavorites.count - 1
                encodeFavorite()
                infoToShow = "Adding " + ticker + " to Favorites"
            }
            else{
                listFavorites.remove(at: indexInFavorite!)
                indexInFavorite = nil
                infoToShow = "Removing " + ticker + " from Favorites"
                encodeFavorite()
            }
            withAnimation{
                showToast = true
                let doLater = Debouncer(delay:1.0)
                doLater.run{
                    withAnimation{
                        showToast = false
                    }
                }
            }
        }, label:{
            if indexInFavorite != nil{
                Image(systemName:"plus.circle.fill")
                    .imageScale(.large)
                    .accessibility(label: Text("Favorite Toggle"))
                    .padding()
            }
            else{
                Image(systemName:"plus.circle")
                    .imageScale(.large)
                    .accessibility(label: Text("Favorite Toggle"))
                    .padding()
            }
        })
    }
    
    let rows = [
        GridItem(.fixed(20)),
        GridItem(.fixed(20)),
        GridItem(.fixed(20))
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment:.leading){
                if showPrice{
                    HStack{
                        Text(name).font(.subheadline).foregroundColor(.gray)
                        Spacer()
                    }.padding(.leading)
                    HStack{
                        Text("$\(price, specifier: "%.2f")").font(.title).bold()
                        Text("($\(change,specifier: "%.2f"))").foregroundColor(change > 0.0 ? .green : .red
                        )
                        Spacer()
                        
                    }.padding(.leading)
                }
                if showHistory{
                    HStack {
                        VStack{
                            let url1 = Bundle.main.url(forResource: "changHighChart", withExtension: "html")!
                            let url2 = URL(string: "?" + ticker, relativeTo: url1)!
                            
                            WebView(title: $title, url: url2)
                                .onLoadStatusChanged {loading, error in
                                    print("url: ", url2)
                                    if loading {
                                        print("Loading started")
                                        self.title = "Loading…"
                                    }
                                    else {
                                        print("Done loading.")
                                        if let error = error {
                                            self.error = error
                                            if self.title.isEmpty {
                                                self.title = "Error"
                                            }
                                        }
                                        else if self.title.isEmpty {
                                            self.title = "StockSearch"
                                        }
                                    }
                                }.frame(height:360.0)
                        }
                    }
                }
                if showPrice{
                    HStack{
                        Text("Portfolio").font(.title)
                    }.padding()
                    HStack{
                        VStack(alignment:.leading){
                            HStack{
                                if indexInList != nil{
                                    VStack (alignment:.leading){
                                        HStack {
                                            Text("Share Owned: \(listStocks[indexInList!].share, specifier: "%.4f")").font(.footnote)
                                        }.padding(.vertical)
                                        HStack {
                                            Text("Market Value: \(listStocks[indexInList!].share * price, specifier: "%.2f")").font(.footnote)
                                        }
                                    }
                                }
                                else{
                                    VStack (alignment:.leading){
                                        HStack {
                                            Text("You have 0 shares of \(ticker)")
                                                .font(.footnote)
                                        }
                                        HStack {
                                            Text("Start trading!")
                                                .font(.footnote)
                                        }
                                    }
                                }
                            }
                        }.sheet(isPresented: $showTradeView){
                            if !showCongrats{
                                tradeView
                            }
                            else{
                                congratsView
                            }
                        }
                        .edgesIgnoringSafeArea(.horizontal)
                        Spacer()
                        Button(action:{
                            showTradeView = true
//                            showCongrats = true
                        },label:{
                            ButtonView(text: "Trade")
                        })
                    }.padding()
                    
                    HStack{
                        Text("Stats").font(.title)
                    }.padding()
                    
                    HStack {
                        ScrollView(.horizontal){
                            LazyHGrid(rows: rows,alignment:.firstTextBaseline){
                                VStack (alignment:.leading){
                                    Text("Current Price: \(price,specifier: "%.2f")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                                VStack (alignment:.leading){
                                    Text("Open Price: \(openPrice,specifier: "%.2f")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                                VStack{
                                    Text("High: \(highPrice,specifier: "%.2f")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                                VStack{
                                    Text("Low: \(lowPrice,specifier: "%.2f")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                                VStack{
                                    Text("Mid: \(mid,specifier: "%.2f")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                                VStack{
                                    Text("Volume: \(volume,specifier: "%d")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                                VStack{
                                    Text("Bid: \(bid,specifier: "%.2f")").font(.footnote)
                                }.frame(width:140,alignment: .leading)
                            }
                        }
                    }.padding()
                    
                    HStack{
                        Text("About").font(.title)
                    }.padding()
                    HStack{
                        Text(description).font(.footnote)
                    }.frame(height: showMore ? nil : 40)
                    .fixedSize(horizontal: false, vertical: showMore)
                    .padding()
                    HStack{
                        Spacer()
                        Button(action: {showMore.toggle()}, label:{
                            Text(showMore ? "show less" : "show more")
                                .font(.caption)
                                .foregroundColor(.gray)
                        })
                    }
                    .padding(.horizontal)
                    
                    NewsView(ticker: ticker).padding()
                    
                    HStack{
                        Button(action:{
                            indexInList = nil
                            indexInFavorite = nil
                            listStocks = []
                            listFavorites = []
                            encodePortfolio()
                            encodeFavorite()
                            money = "20000.00"
                        },label:{
                            ResetButtonView()
                        })
                    }.hidden()
                    .frame(height:10.0)
                    .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                Spacer()
            }.onAppear{
                loadPortfolio()
                loadFavorite()
                singleUpdate(ticker: ticker)
                getDescription(ticker: ticker)
                self.repeating = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) {timer in
                    print("timely updating...")
                    singleUpdate(ticker: ticker)
                }
            }
            .onDisappear{
                print("Detail View distroyed")
                repeating?.invalidate()
            }
        }.navigationTitle(ticker)
        .navigationBarItems(trailing: addButton)
        .toast(isShowing: $showToast, text: Text(infoToShow))
    }
    
    var tradeView: some View {
        VStack(alignment:.leading){
            HStack{
                Button(action:{
                    showTradeView = false
                    showCongrats = false
                },label:{
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                })
                Spacer()
            }.padding()
            HStack{
                Spacer()
                Text("Trade \(name) shares")
                    .bold()
                Spacer()
            }
            Spacer()
            HStack{
                VStack{
                    TextField("0", text: $numToBuy).keyboardType(.numberPad)
                        .font(.system(size: 60))
                }
                VStack{
                    Text("Shares").font(.title)
                }
            }.padding()
            HStack{
                Spacer()
                Text("x $\(price,specifier: "%.2f") =  $\(price * (Float(numToBuy) ?? 0.0), specifier: "%.2f")")
            }.padding()
            Spacer()
            HStack{
                Spacer()
                Text("$\(Float(money ?? "0.0")!, specifier: "%.2f") available to buy \(ticker)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }.padding()
            HStack{
                Button(action:{
                    buyTransaction()
                },label:{
                    ButtonView(text: "Buy")
                })
                Spacer()
                Button(action:{
                    sellTransaction()
                },label:{
                    ButtonView(text: "Sell")
                })
            }.padding()
            Spacer()
        }.toast(isShowing: $showTradeToast, text: Text(infoToShow))
        .frame(maxWidth: .infinity)
        .cornerRadius(20.0)
    }

    var congratsView: some View{
        HStack {
            VStack{
                Spacer()
                Text("Congratulations!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                Text("You have successfully \(buyOrSell) shares \(numToBuy) of \(ticker)")
                    .foregroundColor(.white)
                Spacer()
                Button(action:{
                    showCongrats = false
                    showTradeView = false
                }, label: {
                    CongratsDoneButton()
                })
            }
        }.frame(maxWidth: .infinity)
        .cornerRadius(20.0)
        .background(Color.green)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
    
    private func buyTransaction () -> Void{
        buyOrSell = "bought"
        if let numShare = Float(numToBuy){
            if numShare * price > Float(money!)!{
                infoToShow = "Not enough money to buy..."
                numToBuy = ""
                withAnimation{
                    showTradeToast = true
                    let doLater = Debouncer(delay: 1.0)
                    doLater.run{
                        withAnimation{
                            showTradeToast = false
                        }
                    }
                }
            }
            else if numShare <= 0{
                infoToShow = "Cannot buy 0 or less shares..."
                numToBuy = ""
                withAnimation{
                    showTradeToast = true
                    let doLater = Debouncer(delay: 1.0)
                    doLater.run{
                        withAnimation{
                            showTradeToast = false
                        }
                    }
                }
            }
            else{
                money = String(Float(money!)! - numShare * price)
                if indexInList == nil{
                    listStocks.append(Stock(ticker: self.ticker, name: self.name, avgPrice: price, share: numShare))
                    indexInList = listStocks.count - 1
                    encodePortfolio()
                    withAnimation{
                        showCongrats = true
                    }
                }
                else{
                    let totalInvest = listStocks[indexInList!].avgPrice * listStocks[indexInList!].share + numShare * price
                    let totalShare = listStocks[indexInList!].share + numShare
                    listStocks[indexInList!].share = totalShare
                    listStocks[indexInList!].avgPrice = totalInvest / totalShare
                    encodePortfolio()
                    withAnimation{
                        showCongrats = true
                    }
                }
            }
        }
        else{
            infoToShow = "Please Enter a Valid Amount!"
            numToBuy = ""
            withAnimation{
                showTradeToast = true
                let doLater = Debouncer(delay: 1.0)
                doLater.run{
                    withAnimation{
                        showTradeToast = false
                    }
                }
            }
        }
    }
    
    private func sellTransaction () -> Void{
        buyOrSell = "sold"
        if let numShare = Float(numToBuy){
            if indexInList == nil{
                infoToShow = numShare>0 ? "Not enough shares to sell..." : "Cannot sell 0 or less shares..."
                numToBuy = ""
                withAnimation{
                    showTradeToast = true
                    let doLater = Debouncer(delay: 1.0)
                    doLater.run{
                        withAnimation{
                            showTradeToast = false
                        }
                    }
                }
            }
            else if numShare <= 0 {
                infoToShow = "Cannot sell 0 or less shares..."
                numToBuy = ""
                withAnimation{
                    showTradeToast = true
                    let doLater = Debouncer(delay: 1.0)
                    doLater.run{
                        withAnimation{
                            showTradeToast = false
                        }
                    }
                }
            }
            else if numShare > listStocks[indexInList!].share{
                infoToShow = "Not enough shares to sell..."
                numToBuy = ""
                withAnimation{
                    showTradeToast = true
                    let doLater = Debouncer(delay: 1.0)
                    doLater.run{
                        withAnimation{
                            showTradeToast = false
                        }
                    }
                }
            }
            else{
                money = String(numShare * price + Float(money!)!)
                listStocks[indexInList!].share -= numShare
                listStocks[indexInList!].share = listStocks[indexInList!].share <= 0.00001 ? 0 : listStocks[indexInList!].share
                
                if listStocks[indexInList!].share <= 0.00001{
                    listStocks.remove(at: indexInList!)
                    indexInList = nil
                }
                
                encodePortfolio()
                withAnimation{
                    showCongrats = true
                }
            }
        }
        else{
            infoToShow = "Please Enter a Valid Amount!"
            numToBuy = ""
            withAnimation{
                showTradeToast = true
                let doLater = Debouncer(delay: 1.0)
                doLater.run{
                    withAnimation{
                        showTradeToast = false
                    }
                }
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(ticker: "AAPL", name:"Apple Inc")
    }
}



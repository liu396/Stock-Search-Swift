//
//  ContentView.swift
//  PortableBroker
//
//  Created by liuchang on 12/1/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var searchBar: SearchBar = SearchBar()
    @AppStorage ("savedStocks") var savedStocks: String?
    @AppStorage ("favoriteStocks") var favoriteStocks: String?
    
    @State var repeating: Timer?
    @State var listStocks: [Stock] = []
    @State var listFavorites: [FavoriteStock] = []
    @State var shareOnly: [String:[Float]] = [:]
    @State var showSpinner = true
    @State var allStats: [String:[Float]] = [:]
    @State var virgin = true
    @State var netWorth: Float = 0.0
    
    private func loadPortfolio() -> Void{
        print("loading portfolio...")
        if savedStocks == nil{
            listStocks = []
        }
        else{
            let json = savedStocks!.data(using: .utf8)!
            let product: [Stock]
            do{
                product = try decoder.decode([Stock].self, from: json)
            }
            catch{
                product = []
            }
            listStocks = product
        }
        print("Portfolio got")
        print(listStocks)
        
        let count = listStocks.count
        shareOnly = [:]
        if count != 0{
            for index in 0..<count{
                shareOnly[listStocks[index].ticker] = [listStocks[index].share, listStocks[index].avgPrice]
            }
        }
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
        print("you have \(count) stocks in favorite")
    }
    
    private func readFromMultiple(_ tickers: String){
        if tickers.isEmpty{
            netWorth = 0.0
            allStats = [:]
            virgin = false
            showSpinner = false
            return
        }
        let url = urlLastPrice + tickers
        getJSON(url: url, callback: {json in
            let data = json.arrayValue
            for obj in data{
                allStats[obj["ticker"].stringValue] = [obj["prevClose"].floatValue, obj["last"].floatValue]
            }
            print("Updating Net Worth...")
            netWorth = 0.0
            for stock in listStocks{
                netWorth += stock.share * allStats[stock.ticker]![1]
            }
            showSpinner = false
        })
    }
    
    private func encodePortfolio() -> Void{
        print("Encoding Portfolio...")
        let data: Data?
        do{
            data = try encoder.encode(listStocks)
            savedStocks = String(data:data!, encoding: .utf8)!
        }
        catch{
            data = nil
        }
        print("Encoding Portfolio finished")
    }
    
    private func encodeFavorite() -> Void{
        print("Encoding Favorites...")
        let data: Data?
        do{
            data = try encoder.encode(listFavorites)
            favoriteStocks = String(data:data!, encoding: .utf8)!
        }
        catch{
            data = nil
        }
        print("Encoding Favorite finished")
    }
    
    private func deleteFavorite(offset: IndexSet){
        withAnimation{
            listFavorites.remove(atOffsets: offset)
            encodeFavorite()
        }
    }
    
    private func moveStock(from: IndexSet, to: Int){
        withAnimation{
            listStocks.move(fromOffsets: from, toOffset: to)
            encodePortfolio()
        }
    }
    
    private func moveFavorite(from: IndexSet, to: Int){
        withAnimation{
            listFavorites.move(fromOffsets: from, toOffset: to)
            encodeFavorite()
        }
    }
    
    let date = Date()
    let formatter = DateFormatter()
    var url = ""
    
    init(){
        formatter.dateFormat = "MMMM d, y"
    }
    
    var info: some View{
        NavigationView{
            List{
                ForEach(searchBar.candidates){candidate in
                    NavigationLink(destination:DetailView(ticker:candidate.ticker, name: candidate.name)){
                        VStack(alignment:.leading){
                            Text(candidate.ticker)
                                .font(.headline)
                                .bold()
                            Text(candidate.name)
                                .font(.subheadline)
                        }
                    }
                }
                if searchBar.text.isEmpty{
                    Text(formatter.string(from: date))
                        .font(.title)
                        .foregroundColor(Color.gray)
                        .bold()
                    Section(header:Text("Portfolio")){
                        VStack (alignment: .leading){
                            HStack{
                                Text("Net Worth").font(.title)
                            }
                            HStack{
                                Text("\(netWorth, specifier: "%.2f")").font(.title).bold()
                            }
                        }
                        ForEach(listStocks,id:\.self){item in
                            NavigationLink(destination: DetailView(ticker: item.ticker, name: item.name)){
                                VStack(alignment:.leading){
                                    Text(item.ticker)
                                        .font(.headline)
                                        .bold()
                                    Text("\(item.share, specifier: "%.2f") shares")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                VStack(alignment:.trailing){
                                    HStack{
                                        Text("\(allStats[item.ticker]![1] , specifier:"%.2f")")
                                    }
                                    HStack{
                                        if(allStats[item.ticker]![1] > item.avgPrice){
                                            Image(systemName: "arrow.up.right")
                                                .foregroundColor(.green)
                                            Text("\(allStats[item.ticker]![1] - item.avgPrice, specifier: "%.2f")")
                                                .foregroundColor(.green)
                                        }
                                        else{
                                            Image(systemName:"arrow.down.right")
                                                .foregroundColor(.red)
                                            Text("\(allStats[item.ticker]![1] - item.avgPrice, specifier: "%.2f")")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }.onMove(perform:moveStock)
                    }
                    Section(header:Text("Favorites")){
                        ForEach(listFavorites, id:\.self){stock in
                            NavigationLink(destination:DetailView(ticker:stock.ticker, name: stock.name)){
                                if shareOnly[stock.ticker] != nil {
                                    VStack(alignment:.leading){
                                        Text(stock.ticker)
                                            .font(.headline)
                                            .bold()
                                        Text("\(shareOnly[stock.ticker]![0], specifier: "%.2f") shares")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    VStack(alignment:.trailing){
                                        HStack{
                                            Text("\(allStats[stock.ticker]![1] , specifier:"%.2f")")
                                        }
                                        HStack{
                                            if(allStats[stock.ticker]![1] > shareOnly[stock.ticker]![1]){
                                                Image(systemName: "arrow.up.right")
                                                    .foregroundColor(.green)
                                                Text("\(allStats[stock.ticker]![1] - shareOnly[stock.ticker]![1], specifier: "%.2f")")
                                                    .foregroundColor(.green)
                                            }
                                            else{
                                                Image(systemName:"arrow.down.right")
                                                    .foregroundColor(.red)
                                                Text("\(allStats[stock.ticker]![1] - shareOnly[stock.ticker]![1], specifier: "%.2f")")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                                else{
                                    VStack(alignment:.leading){
                                        Text(stock.ticker)
                                            .font(.headline)
                                            .bold()
                                        Text(stock.name)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    VStack{
                                        HStack{
                                            Text("\(allStats[stock.ticker]![1], specifier: "%.2f")")
                                        }
                                        HStack{
                                            if(allStats[stock.ticker]![1] > allStats[stock.ticker]![0]){
                                                Image(systemName: "arrow.up.right")
                                                    .foregroundColor(.green)
                                                Text("\(allStats[stock.ticker]![1] - allStats[stock.ticker]![0], specifier: "%.2f")")
                                                    .foregroundColor(.green)
                                            }
                                            else{
                                                Image(systemName:"arrow.down.right")
                                                    .foregroundColor(.red)
                                                Text("\(allStats[stock.ticker]![1] - allStats[stock.ticker]![0], specifier: "%.2f")")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            }
                        }.onDelete(perform:deleteFavorite)
                        .onMove(perform:moveFavorite)
                        VStack(alignment:.center){
                            HStack{
                                Spacer()
                                Link(destination: URL(string: "https://www.tiingo.com")!){
                                    Text("Powered by Tiingo").font(.footnote).foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }.navigationBarTitle(Text("Stocks"))
            .toolbar{
                EditButton()
            }
            .add(searchBar)
            .onAppear{
                print("showSpinner: ",showSpinner)
                print("showVirgin: ", virgin)
                print("Mother View shown...")
                if virgin{
                    virgin = false
                    return
                }
                else{
                    print("retriving data...")
                    loadPortfolio()
                    loadFavorite()//For portfolio
                    var queryList:[String] = []
                    for item in listStocks{
                        let key = item.ticker
                        if allStats[key] == nil{
                            allStats[key] = [0.0, 0.0]
                        }
                        queryList.append(item.ticker)
                    }
                    
                    for item in listFavorites{
                        let key = item.ticker
                        if allStats[key] == nil{
                            allStats[key] = [0.0, 0.0]
                        }
                        queryList.append(key)
                    }
                    
                    let queryString = queryList.joined(separator: ",")
                    print(queryString)
                    readFromMultiple(queryString)
                    self.repeating = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) {timer in
                        print("timely updating all stock info...")
                        readFromMultiple(queryString)
                    }
                }
                
            }
            .onDisappear{
                print("Mother View Destroyed")
                repeating?.invalidate()
            }
        }
    }
    
    var body: some View {
        if !showSpinner{
            info
        }
        else{
            VStack{
                ProgressView()
                Text("Fetching Data... ")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .onAppear{
                print("retriving data...")
                loadPortfolio()
                loadFavorite()
                var queryList:[String] = []
                for item in listStocks{
                    let key = item.ticker
                    if allStats[key] == nil{
                        queryList.append(key)
                        allStats[key] = [0.0, 0.0]
                    }
                }
                for item in listFavorites{
                    let key = item.ticker
                    if allStats[key] == nil{
                        queryList.append(key)
                        allStats[key] = [0.0, 0.0]
                    }
                }
                
                let queryString = queryList.joined(separator: ",")
                print(queryString)
                readFromMultiple(queryString)
                self.repeating = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) {timer in
                    print("timely updating all stock info...")
                    readFromMultiple(queryString)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

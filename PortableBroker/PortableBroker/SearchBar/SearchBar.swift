//
//  SearchBar.swift
//  StockSearch
//
//  Created by liuchang on 11/17/20.
//

import SwiftUI
import SwiftyJSON

class SearchBar: NSObject, ObservableObject {
    
    @Published var text: String = ""
    @Published var candidates: [AutoCandidate] = []
    let searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    let timer = Debouncer(delay: 1.5)
    
    override init() {
        super.init()
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
    }
}

extension SearchBar: UISearchResultsUpdating {
   
    private func updateCandidates(_ json: JSON){
        if self.text.count<3{
            return
        }
        print(json)
        candidates = []
        for item in json.arrayValue{
            candidates.append(AutoCandidate(ticker:item["ticker"].stringValue, name:item["name"].stringValue))
        }
    }

    
    func updateSearchResults(for searchController: UISearchController) {
        
        // Publish search bar text changes.
        if let searchBarText = searchController.searchBar.text {
            self.text = searchBarText
            if self.text.count < 3{
                timer.run(action:{})
                candidates = []
                return
            }
            else{
                timer.run(action: {getJSON(url:urlAutoCompelete + self.text,callback: self.updateCandidates(_:))})
            }
        }
    }
}

struct SearchBarModifier: ViewModifier {
    
    let searchBar: SearchBar
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ViewControllerResolver { viewController in
                    viewController.navigationItem.searchController = self.searchBar.searchController
                }
                    .frame(width: 0, height: 0)
            )
    }
}

extension View {
    
    func add(_ searchBar: SearchBar) -> some View {
        return self.modifier(SearchBarModifier(searchBar: searchBar))
    }
}


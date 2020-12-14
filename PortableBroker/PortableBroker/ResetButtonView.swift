//
//  ResetButtonView.swift
//  StockSearch
//
//  Created by liuchang on 11/26/20.
//

import SwiftUI

struct ResetButtonView: View {
    var body: some View {
        VStack{
            Text("Reset")
                .bold()
                .frame(width: 260,
                       height: 50)
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(50)
                .padding()
        }
    }
}

struct ResetButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ResetButtonView()
    }
}


//
//  ButtonView.swift
//  StockSearch
//
//  Created by liuchang on 11/26/20.
//

import SwiftUI

struct ButtonView: View {
    var text: String
    var body: some View {
        VStack{
            Text(text)
                .bold()
                .frame(width: 120,
                       height: 50)
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(50)
        }
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(text: "Trade")
    }
}


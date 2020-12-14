//
//  CongratsDoneButton.swift
//  StockSearch
//
//  Created by liuchang on 11/26/20.
//

import SwiftUI

struct CongratsDoneButton: View {
    var body: some View {
        VStack{
            Text("Done")
                .bold()
                .frame(width: 260,
                       height: 50)
                .foregroundColor(.green)
                .background(Color.white)
                .cornerRadius(50)
                .padding()
        }
    }
}

struct CongratsDoneButton_Previews: PreviewProvider {
    static var previews: some View {
        CongratsDoneButton()
    }
}


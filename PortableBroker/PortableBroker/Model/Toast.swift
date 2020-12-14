//
//  Toast.swift
//  StockSearch
//
//  Created by liuchang on 11/26/20.
//

import SwiftUI

struct Toast<Presenting>: View where Presenting: View {
    /// The binding that decides the appropriate drawing in the body.
    @Binding var isShowing: Bool
    /// The view that will be "presenting" this toast
    let presenting: () -> Presenting
    /// The text to show
    let text: Text

    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .bottom){
                self.presenting()
                    .blur(radius: 0)
                VStack {
                    self.text
                }
                .frame(width: geometry.size.width / 1.2,
                       height: geometry.size.height / 10)
                .background(Color.secondary)
                .foregroundColor(.white)
                .cornerRadius(50)
                .transition(.slide)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, text: Text) -> some View {
        Toast(isShowing: isShowing,
              presenting: { self },
              text: text)
    }
}



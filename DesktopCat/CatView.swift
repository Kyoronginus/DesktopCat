//
//  Untitled.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import SwiftUI

struct CatView: View {
    var body: some View{
        ZStack {
            Image("default_left")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        }
    }
}


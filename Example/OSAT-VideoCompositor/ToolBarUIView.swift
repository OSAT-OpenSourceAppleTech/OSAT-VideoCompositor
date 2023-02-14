//
//  ToolBarUIView.swift
//  OSAT_SwiftUI
//
//  Created by Rohit Sharma on 13/02/23.
//

import SwiftUI

struct ButtonWithAction: Hashable {
    var identifier: String {
        return UUID().uuidString
    }
    static func == (lhs: ButtonWithAction, rhs: ButtonWithAction) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    let imageString: String
    let completionHandler: () -> ()
}

struct ToolBarUIView: View {
    private var rows = [GridItem(.fixed(40))]
    private var colors: [Color] = [.yellow, .purple, .green]
    @State private var buttons: [ButtonWithAction] = [
        ButtonWithAction(imageString: "plus", completionHandler: {
            print("pluse")
        }),
        ButtonWithAction(imageString: "t.square.fill", completionHandler: {
            print("t")
        }),
        ButtonWithAction(imageString: "photo", completionHandler: {
            print("photo")
        }),
        ButtonWithAction(imageString: "camera.filters", completionHandler: {
            print("camer.filters")
        })
    ]
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: rows, alignment: .center, spacing: 16) {
                ForEach(buttons, id: \.self) { item in
                    Button {
                        item.completionHandler()
                    } label: {
                        Image(systemName: item.imageString)
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                            .frame(width: 40, height: 40)
                            .background(.black)
                            .cornerRadius(10)
                    }
                    
                }
            }.padding()
        }.fixedSize(horizontal: false, vertical: true)
    }
}

struct ToolBarUIView_Previews: PreviewProvider {
    static var previews: some View {
        ToolBarUIView().frame(height: 150)
    }
}

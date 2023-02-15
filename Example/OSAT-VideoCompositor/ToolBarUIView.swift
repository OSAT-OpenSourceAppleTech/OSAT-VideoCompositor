//
//  ToolBarUIView.swift
//  OSAT_SwiftUI
//
//  Created by Rohit Sharma on 13/02/23.
//

import SwiftUI
import PhotosUI

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

@available(iOS 16.0, *)
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
    @State private var item: PhotosPickerItem?
    var body: some View {
        HStack {
            PhotosPicker(selection: $item) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 25))
                    .frame(width: 40, height: 40)
                    .background(.black)
                    .cornerRadius(10)
            }
//            Button {
//                //item.completionHandler()
//            } label: {
//                
//            }
            
            Button {
                //item.completionHandler()
            } label: {
                Image(systemName: "t.square.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 25))
                    .frame(width: 40, height: 40)
                    .background(.black)
                    .cornerRadius(10)
            }
            
            Button {
                //item.completionHandler()
            } label: {
                Image(systemName: "photo")
                    .foregroundColor(.white)
                    .font(.system(size: 25))
                    .frame(width: 40, height: 40)
                    .background(.black)
                    .cornerRadius(10)
            }
            
            Button {
                //item.completionHandler()
            } label: {
                Image(systemName: "camera.filters")
                    .foregroundColor(.white)
                    .font(.system(size: 25))
                    .frame(width: 40, height: 40)
                    .background(.black)
                    .cornerRadius(10)
            }
        }.padding()
    }
}

@available(iOS 16.0, *)
struct PickerView: View {
    @State var selectedItems: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        PhotosPicker(selection: $selectedItems, matching: .videos) {
            Text("hey")
        }.onChange(of: selectedItems) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedPhotoData = data
                }
            }
        }
    }
}

struct ToolBarUIView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            ToolBarUIView().frame(height: 150)
        } else {
            // Fallback on earlier versions
        }
    }
}

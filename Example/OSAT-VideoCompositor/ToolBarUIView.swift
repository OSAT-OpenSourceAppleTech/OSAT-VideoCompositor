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
    @State private var watermarkText: String = ""
    @State private var watermarkFontSize: CGFloat = 12
    @State private var watermarkTextColor: CGColor = UIColor.red.cgColor
    @State private var watermarkTextFrame: CGRect = .zero
    @State private var watermarkImageFrame: CGRect = .zero
    @State private var watermarkImageFile: URL = URL(filePath: "")
    @State private var username: String = ""
    
    private var textLayer: CATextLayer {
        let layer = CATextLayer()
        layer.fontSize = watermarkFontSize
        layer.frame = watermarkTextFrame
        layer.foregroundColor = watermarkTextColor
        layer.string = username
        layer.name = "WatermarkTextLayer"
        return layer
    }
    
    private var imageLayer: CALayer {
        let layer = CALayer()
        layer.contents = UIImage(named: "Webex")?.cgImage
        layer.frame = watermarkImageFrame
        layer.name = "WatermarkImageLayer"
        return layer
    }
    
    @EnvironmentObject var playerInstance: PlayerViewModel
    private var rows = [GridItem(.fixed(40))]
    private var colors: [Color] = [.yellow, .purple, .green]
    @State private var showTextAlert = false
    @State private var showFileImporter = false
    @State private var bgColor = Color.red
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
            Button {
                showFileImporter.toggle()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 25))
                        .frame(width: 40, height: 40)
                        .background(.black)
                        .cornerRadius(10)
                    Text("Add Video")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }.fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image, .video]) { result in
                do {
                    playerInstance.inputVideoURL = try result.get()
                } catch {
                    print(error)
                }
                
            }
            
            Button {
                showTextAlert.toggle()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "t.square.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 25))
                        .frame(width: 40, height: 40)
                        .background(.black)
                        .cornerRadius(10)
                    Text("Add Text")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }.alert("Add Text", isPresented: $showTextAlert) {
                TextField("Add Text", text: $username).foregroundColor(.white)
                Button("Show Preview", action: {
                    textLayer.string = username
                    playerInstance.addTextLayer(layer: textLayer)
                    username = ""
                })
            }
            
            Button {
                playerInstance.currentImage = UIImage(named: "Webex")
                playerInstance.showPreview(layer: imageLayer, image: playerInstance.currentImage!)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .foregroundColor(.white)
                        .font(.system(size: 25))
                        .frame(width: 40, height: 40)
                        .background(.black)
                        .cornerRadius(10)
                    Text("Add Image")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            Button {
                playerInstance.updateLoopValue(!playerInstance.loopButtonState)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName:  playerInstance.loopButtonState ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                        .foregroundColor(.white)
                        .font(.system(size: 25))
                        .frame(width: 40, height: 40)
                        .background(.black)
                        .cornerRadius(10)
                    Text(playerInstance.loopButtonState ? "Stop Loop" : "Start Loop")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
               
            }
            
            
            Button {
                playerInstance.removePreviews()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName:  "pip.remove")
                        .foregroundColor(.white)
                        .font(.system(size: 25))
                        .frame(width: 40, height: 40)
                        .background(.black)
                        .cornerRadius(10)
                    Text("Remove")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                
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
    @StateObject static var playerInstance = PlayerViewModel()
    static var previews: some View {
        if #available(iOS 16.0, *) {
            ZStack {
                Color.gray.ignoresSafeArea()
                ToolBarUIView().frame(height: 150)
                    .environmentObject(playerInstance)
            }
           
        } else {
            // Fallback on earlier versions
        }
    }
}

//
//  Home.swift
//  ImageCropping
//
//  Created by Đoàn Văn Khoan on 1/12/24.
//

import SwiftUI

struct Home: View {
    
    @State private var showPicker: Bool = false
    @State private var croppedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let croppedImage {
                    Image(uiImage: croppedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 400)
                } else {
                    Text("No Image is Selected")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Crop Image Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPicker.toggle()
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.callout)
                    }
                    .tint(.black)
                }
            }
            .cropImagePicker(options: [.circle,.square,.rectangle], show: $showPicker, croppedImage: $croppedImage)
        }
    }
}

#Preview {
    Home()
}

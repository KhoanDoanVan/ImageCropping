//
//  CustomImagePIcker.swift
//  ImageCropping
//
//  Created by Đoàn Văn Khoan on 1/12/24.
//

import SwiftUI
import PhotosUI

// MARK: View Extension
extension View {
    @ViewBuilder
    func cropImagePicker(options: [Crop], show: Binding<Bool>, croppedImage: Binding<UIImage?>) -> some View {
        CustomImagePicker(options: options, show: show, croppedImage: croppedImage) {
            self
        }
    }
    
    @ViewBuilder
    func frame(_ size: CGSize) -> some View {
        self
            .frame(width: size.width, height: size.height)
    }
}


fileprivate struct CustomImagePicker<Content: View>: View {
    
    var content: Content
    var options: [Crop]
    @Binding var show: Bool
    @Binding var croppedImage: UIImage?
    
    init(
        options: [Crop],
        show: Binding<Bool>,
        croppedImage: Binding<UIImage?>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
        self._show = show
        self._croppedImage = croppedImage
        self.options = options
    }
    
    @State private var photosItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showDialog: Bool = false
    @State private var selectedCropType: Crop = .circle
    @State private var showCropView: Bool = false
    
    var body: some View {
        content
            .photosPicker(isPresented: $show, selection: $photosItem)
            .onChange(of: photosItem) { oldValue, newValue in
                if let newValue {
                    Task {
                        if let  imageData = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: imageData)
                        {
                            await MainActor.run {
                                selectedImage = image
                                showDialog.toggle()
                            }
                        }
                    }
                }
            }
            .confirmationDialog("", isPresented: $showDialog) {
                /// Display all the options
                ForEach(options.indices, id: \.self) { index in
                    Button(options[index].name()) {
                        selectedCropType = options[index]
                        showCropView.toggle()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCropView) {
                selectedImage = nil
            } content: {
                CropView(crop: selectedCropType, image: selectedImage) { croppedImage, status in
                    
                }
            }
    }
}

struct CropView: View {
    var crop: Crop
    var image: UIImage?
    var onCrop: (UIImage?, Bool) -> ()
    
    @Environment(\.dismiss) private var dismiss
    /// Gesture Properties
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    @GestureState private var isInteracting: Bool = false
    
    var body: some View {
        NavigationStack {
            ImageView()
                .navigationTitle("Crop View")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    Color.black
                        .ignoresSafeArea()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    func ImageView() -> some View {
        let cropSize = crop.size()
        GeometryReader {
            let size = $0.size
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(size)
                    /// Don't usage onEnded() because not working in this situation
                    .onChange(of: isInteracting) { oldValue, newValue in
                        /// - True: Dragging
                        /// - False: Stopped Dragging
                        if !newValue {
                            /// - Storing Last Offset
                            lastStoredOffset = offset
                        }
                    }
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .overlay(content: {
            Grids()
        })
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                })
                .onChanged(
                    { value in
                        let translation = value.translation
                        offset = CGSize(
                            width: translation.width + lastStoredOffset.width,
                            height: translation.height + lastStoredOffset.height
                        )
                })
        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                })
                .onChanged({ value in
                    let updatedScale = value + lastScale
                    /// - Limiting Beyond 1
                    scale = (updatedScale < 1 ? 1 : updatedScale)
                })
                .onEnded({ value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if scale < 1 {
                            scale = 1
                            lastScale = 0
                        } else {
                            lastScale = scale - 1
                        }
                    }
                })
        )
        .frame(cropSize)
        .cornerRadius(crop == .circle ? cropSize.height / 2 : 0)
    }
    
    @ViewBuilder
    func Grids() -> some View {
        ZStack {
            HStack {
                ForEach(1...5, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 1)
                        .frame(maxWidth: .infinity)
                }
            }
            
            VStack {
                ForEach(1...8, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(height: 1)
                        .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

#Preview(body: {
    Home()
})

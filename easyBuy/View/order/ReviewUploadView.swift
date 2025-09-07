import SwiftUI
import CryptoKit


enum PickerType: Identifiable {
    case photoLibrary
    case camera
    var id: Int { hashValue }
}


struct ReviewUploadView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var router: PageRouter

    @State private var rating = 0
    @State private var comment: String = ""
    @State private var selectedPhotos: [SelectedPhoto] = []
    @State private var showImagePickerType: PickerType? = nil
    @State private var sourceType: ImagePickerSourceType = .photoLibrary
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isLoading: Bool = false

    let orderId: String

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack {
                HStack { }.frame(height: 30)
                List {
                    Section(header: Text("Review Content")) {
                        HStack {
                            Text("Rating：")
                            StarRating(rating: $rating)
                            Text("\(rating) / 5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        TextField("Write something...", text: $comment)
                            .frame(height: 120, alignment: .topLeading)
                    }

                    Section(header: Text("Add Photos (up to 5)")) {
                        Button("Choose from Album") {
                            showImagePickerType = .photoLibrary
                        }

                        Button("Camera") {
                            showImagePickerType = .camera
                        }

                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedPhotos) { photo in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: photo.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.black.opacity(0.7))
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .offset(x: 4, y: -8)
                                            .onTapGesture {
                                                selectedPhotos.removeAll { $0.id == photo.id }
                                            }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                PrimaryFilledButton(title: "Post Review") {
                    isLoading = true
                    vm.rating = rating
                    vm.comment = comment
                    vm.selectedImages = selectedPhotos.map { $0.image }

                    Task {
                        await vm.addReview(orderId: orderId)
                        
                        await MainActor.run {
                            isLoading = false
                            router.pop()
                        }
                    }
                }
                .disabled(rating == 0)
                .padding(24)
                HStack { }.frame(height: 50)
            }

            HeaderView(text: "Post Review", bgColor: .bg, showBackButton: true)
            
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                .transition(.opacity)
                .zIndex(99)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $showImagePickerType) { type in
            ImagePicker(
                sourceType: type == .photoLibrary ? .photoLibrary : .camera,
                maxCount: 5,
                maxFileSizeKB: 5,
                selectedPhotos: $selectedPhotos,
                alertMessage: $alertMessage,
                showAlert: $showAlert
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Reminder"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ReviewUploadView(orderId: "order123")
        .environmentObject(AuthViewModel.preview())
}



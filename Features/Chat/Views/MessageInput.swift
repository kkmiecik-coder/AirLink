//
//  MessageInput.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI
import PhotosUI

// MARK: - MessageInput

/// Komponenty do wprowadzania wiadomości w czacie
/// Obsługuje tekst, załączniki, emoji oraz akcje specjalne
struct MessageInput: View {
    
    // MARK: - Bindings
    
    @Binding var messageText: String
    @Binding var attachments: [PendingAttachment]
    
    // MARK: - Properties
    
    let isSending: Bool
    let canSend: Bool
    let onSend: () -> Void
    let onAddAttachment: () -> Void
    
    // MARK: - State
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var textHeight: CGFloat = 36
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Constants
    
    private let maxTextHeight: CGFloat = 120
    private let minTextHeight: CGFloat = 36
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Attachments preview
            if !attachments.isEmpty {
                attachmentsPreview
            }
            
            // Input container
            inputContainer
        }
        .background(AirLinkColors.backgroundSecondary)
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotos,
            maxSelectionCount: 5,
            matching: .images
        )
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                addImageAttachment(image)
            }
        }
        .onChange(of: selectedPhotos) { _, newPhotos in
            processSelectedPhotos(newPhotos)
        }
    }
    
    // MARK: - Input Container
    
    private var inputContainer: some View {
        HStack(alignment: .bottom, spacing: AppTheme.current.spacing.sm) {
            
            // Attachment button
            attachmentButton
            
            // Text input
            messageTextInput
            
            // Send button
            sendButton
        }
        .padding(.horizontal, AppTheme.current.spacing.md)
        .padding(.vertical, AppTheme.current.spacing.sm)
    }
    
    // MARK: - Attachment Button
    
    private var attachmentButton: some View {
        Menu {
            Button("Zdjęcie z galerii") {
                showingImagePicker = true
            }
            .labelStyle(.titleAndIcon)
            .symbolVariant(.fill)
            
            Button("Zrób zdjęcie") {
                showingCamera = true
            }
            .labelStyle(.titleAndIcon)
            .symbolVariant(.fill)
            
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(AirLinkColors.primary)
        }
        .disabled(isSending)
    }
    
    // MARK: - Message Text Input
    
    private var messageTextInput: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 18)
                .fill(AirLinkColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AirLinkColors.borderLight, lineWidth: 1)
                )
            
            // Text field
            TextField("Wiadomość...", text: $messageText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(AppTheme.current.typography.body)
                .lineLimit(1...6)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .disabled(isSending)
                .onSubmit {
                    if canSend && !messageText.isEmpty {
                        onSend()
                    }
                }
        }
        .frame(minHeight: minTextHeight)
        .animation(AppTheme.current.animations.fast, value: textHeight)
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button(action: onSend) {
            ZStack {
                Circle()
                    .fill(canSend ? AirLinkColors.primary : AirLinkColors.backgroundTertiary)
                    .frame(width: 36, height: 36)
                
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canSend ? .white : AirLinkColors.textTertiary)
                }
            }
        }
        .disabled(!canSend || isSending)
        .scaleEffect(canSend ? 1.0 : 0.8)
        .animation(AppTheme.current.animations.spring, value: canSend)
    }
    
    // MARK: - Attachments Preview
    
    private var attachmentsPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.current.spacing.sm) {
                ForEach(attachments.indices, id: \.self) { index in
                    AttachmentPreview(
                        attachment: attachments[index],
                        onRemove: { removeAttachment(at: index) }
                    )
                }
            }
            .padding(.horizontal, AppTheme.current.spacing.md)
        }
        .padding(.vertical, AppTheme.current.spacing.sm)
        .background(AirLinkColors.backgroundTertiary)
    }
    
    // MARK: - Helper Methods
    
    private func processSelectedPhotos(_ photos: [PhotosPickerItem]) {
        Task {
            for photo in photos {
                if let data = try? await photo.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        addImageAttachment(image)
                    }
                }
            }
            
            await MainActor.run {
                selectedPhotos.removeAll()
            }
        }
    }
    
    private func addImageAttachment(_ image: UIImage) {
        let attachment = PendingAttachment(
            id: UUID().uuidString,
            type: .image,
            image: image
        )
        attachments.append(attachment)
    }
    
    private func removeAttachment(at index: Int) {
        withAnimation(AppTheme.current.animations.fast) {
            attachments.remove(at: index)
        }
    }
}

// MARK: - Attachment Preview

private struct AttachmentPreview: View {
    
    let attachment: PendingAttachment
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image preview
            if let image = attachment.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 20, height: 20)
                    )
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Camera View

private struct CameraView: UIViewControllerRepresentable {
    
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImageCaptured(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImageCaptured(originalImage)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Pending Attachment

struct PendingAttachment: Identifiable {
    let id: String
    let type: AttachmentType
    let image: UIImage?
    let data: Data?
    
    init(id: String, type: AttachmentType, image: UIImage? = nil, data: Data? = nil) {
        self.id = id
        self.type = type
        self.image = image
        self.data = data
    }
    
    enum AttachmentType {
        case image
        case document
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        MessageInput(
            messageText: .constant("Przykładowa wiadomość..."),
            attachments: .constant([]),
            isSending: false,
            canSend: true,
            onSend: {},
            onAddAttachment: {}
        )
    }
    .background(AirLinkColors.background)
    .withAppTheme()
}

#Preview("With Attachments") {
    VStack {
        Spacer()
        
        MessageInput(
            messageText: .constant("Zdjęcia z wczoraj"),
            attachments: .constant([
                PendingAttachment(id: "1", type: .image, image: UIImage(systemName: "photo")!),
                PendingAttachment(id: "2", type: .image, image: UIImage(systemName: "photo")!)
            ]),
            isSending: false,
            canSend: true,
            onSend: {},
            onAddAttachment: {}
        )
    }
    .background(AirLinkColors.background)
    .withAppTheme()
}

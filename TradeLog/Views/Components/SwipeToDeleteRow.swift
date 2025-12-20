import SwiftUI

struct SwipeToDeleteRow<Content: View>: View {
    let content: Content
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isDeleting = false
    
    init(@ViewBuilder content: () -> Content, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack {
            // Background Delete Action
            // This sits behind the content. We use geometry of content to size it if possible, 
            // but in a ZStack, if content defines size, this layer fills it.
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation { isDeleting = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDelete()
                    }
                }) {
                    ZStack {
                        Color.red
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80)
                    // Match the card's visual style so it looks like it's "under" the card
                    .cornerRadius(16) 
                }
            }
            .opacity(offset < -10 ? 1 : 0) // Fade in or hide to avoid clicking through?
            
            // Foreground Content
            content
                .background(Color(.systemGroupedBackground)) // Hide the button behind
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            // Only interpret as swipe if horizontal drag > vertical drag
                            if abs(value.translation.width) > abs(value.translation.height) {
                                if value.translation.width < 0 {
                                    offset = value.translation.width
                                }
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if value.translation.width < -100 {
                                    offset = -120 // Open State
                                    // Could also auto-delete if swiped far enough, but let's stick to reveal
                                } else {
                                    offset = 0 // Closed State
                                }
                            }
                        }
                )
        }
    }
}

import SwiftUI

/// An overlay with a semi-transparent background and activity spinner.
struct LoadingOverlay: View {
    var message: String = "Please wait..."
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)
                
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.darkGray).opacity(0.85))
            )
            .shadow(radius: 10)
        }
    }
}

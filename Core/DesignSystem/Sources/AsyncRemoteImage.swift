import SwiftUI

public struct AsyncRemoteImage: View {
    private let urlString: String
    private let contentMode: ContentMode

    public init(urlString: String, contentMode: ContentMode = .fit) {
        self.urlString = urlString
        self.contentMode = contentMode
    }

    public var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    DesignTokens.Colors.background
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                ZStack {
                    DesignTokens.Colors.background
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}

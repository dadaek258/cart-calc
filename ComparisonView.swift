import SwiftUI

struct ComparisonView: View {
    var body: some View {
        VStack {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .padding(.bottom)
            Text("비교 카테고리")
                .font(.title)
                .padding(.bottom, 4)
            Text("여기에 비교 기능을 추가하세요.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ComparisonView()
}

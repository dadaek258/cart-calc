import Foundation

struct MemoItem: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var isDone: Bool = false
}
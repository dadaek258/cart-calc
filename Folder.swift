import SwiftUI

struct Folder: Identifiable {
    let id: UUID
    var name: String
    var color: Color
    var memos: [MemoItem]
    
    init(id: UUID = UUID(), name: String, color: Color, memos: [MemoItem] = []) {
        self.id = id
        self.name = name
        self.color = color
        self.memos = memos
    }
}

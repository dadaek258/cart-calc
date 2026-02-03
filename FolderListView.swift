import SwiftUI

struct FolderListView: View {
    @State private var folders: [Folder] = []
    @State private var showingAddFolder = false
    @State private var newFolderName = ""
    @State private var newFolderColor: Color = .blue
    @State private var selectedFolder: Folder?
    
    let folderColors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .yellow, .teal, .gray]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(folders) { folder in
                    NavigationLink(value: folder.id) {
                        HStack {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 24, height: 24)
                            Text(folder.name)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indices in
                    folders.remove(atOffsets: indices)
                }
            }
            .navigationTitle("폴더")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFolder) {
                VStack(spacing: 24) {
                    Text("새 폴더 추가")
                        .font(.headline)
                    TextField("폴더 이름", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    HStack {
                        ForEach(folderColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.black.opacity(newFolderColor == color ? 0.2 : 0), lineWidth: 2)
                                )
                                .onTapGesture {
                                    newFolderColor = color
                                }
                        }
                    }
                    Button("추가하기") {
                        let folder = Folder(name: newFolderName, color: newFolderColor)
                        folders.append(folder)
                        newFolderName = ""
                        newFolderColor = .blue
                        showingAddFolder = false
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                .presentationDetents([.medium])
                .padding()
            }
            .navigationDestination(for: UUID.self) { folderID in
                if let idx = folders.firstIndex(where: { $0.id == folderID }) {
                    MemoView(folder: $folders[idx], allFolders: $folders)
                }
            }
        }
    }
}

#Preview {
    FolderListView()
}

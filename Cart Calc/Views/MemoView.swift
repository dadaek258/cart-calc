//
//  MemoView.swift
//  Cart Calc
//
//  Created by 이다은 on 1/15/26.
//

import SwiftUI

struct MemoView: View {
    @Binding var folders: [Folder]
    let folderId: UUID
    @Binding var transferItemText: String?
    @Binding var selectedTab: Int

    @State private var memoItems: [MemoItem] = []

    @State private var showTransferAlert: Bool = false
    @State private var transferIdx: Int? = nil

    @State private var showDeleteAlert: Bool = false
    @State private var deleteIdx: Int? = nil

    @State private var showSelectedDeleteAlert: Bool = false
    @State private var selectAll: Bool = false
    @FocusState private var draftFieldFocused: Bool
    @State private var draftMemoText: String = ""

    init(folders: Binding<[Folder]>, selectedTab: Binding<Int>, folderId: UUID, transferItemText: Binding<String?>) {
        self._folders = folders
        self._selectedTab = selectedTab
        self.folderId = folderId
        self._transferItemText = transferItemText
    }

    private var folderIndex: Int? {
        return folders.firstIndex(where: { folder in
            folder.id == folderId
        })
    }
    
    private var folderName: String {
        if let idx = folderIndex {
            return folders[idx].name
        }
        return "메모"
    }

    var body: some View {
        VStack {
            List {
                Section(header: SectionHeader(selectAll: $selectAll, hasAnySelected: hasAnySelected, onToggleAll: toggleAllSelected, onDeleteSelected: { showSelectedDeleteAlert = true })) {
                    if memoItems.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Text("메모가 없습니다")
                                .foregroundColor(.secondary)
                            Text("메모 내용을 입력한 뒤 + 버튼을 누르세요")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    ForEach(memoItems) { item in
                        MemoRow(
                            item: item,
                            onToggle: { toggleItem(item) },
                            onRename: { beginRename(item) },
                            onTransfer: { beginTransfer(item) },
                            onDelete: { beginDelete(item) }
                        )
                    }
                    DraftRow(
                        text: $draftMemoText,
                        focused: $draftFieldFocused,
                        onCommit: addDraftMemo
                    )
                }
            }
        }
        .onAppear(perform: loadFolder)
        .onChange(of: memoItems) { newItems in
            if let idx = folderIndex {
                folders[idx].memos = newItems
            }
        }
        .onChange(of: memoItems) { newItems in
            if newItems.isEmpty {
                selectAll = false
            } else {
                selectAll = newItems.allSatisfy { $0.isDone }
            }
        }
        .alert("계산기 품명으로 이동하시겠습니까?", isPresented: $showTransferAlert) {
            Button("취소", role: .cancel) {}
            Button("확인") {
                if let idx = transferIdx {
                    transferItemText = memoItems[idx].text
                    selectedTab = 1
                    memoItems.remove(at: idx)
                }
            }
        } message: {
            Text("해당 메모가 계산기에 복사되어 품명에 입력됩니다.")
        }
        .alert("품목을 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) {
                if let idx = deleteIdx {
                    memoItems.remove(at: idx)
                }
                deleteIdx = nil
            }
        } message: {
            Text("메모가 목록에서 삭제됩니다.")
        }
        .alert("선택한 메모를 삭제하시겠습니까?", isPresented: $showSelectedDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) {
                memoItems.removeAll(where: { $0.isDone })
            }
        } message: {
            Text("선택한 메모들이 목록에서 삭제됩니다.")
        }
        .sheet(isPresented: isRenameSheetPresented) {
            RenameSheet(
                title: "메모 이름 변경",
                text: $draftMemoText,
                onCancel: {
                    transferIdx = nil
                    draftMemoText = ""
                },
                onDone: {
                    if let idx = transferIdx {
                        let trimmed = draftMemoText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            memoItems[idx].text = trimmed
                        }
                    }
                    transferIdx = nil
                    draftMemoText = ""
                }
            )
        }
        .navigationTitle(folderName)
    }

    private var isRenameSheetPresented: Binding<Bool> {
        Binding<Bool>(
            get: { transferIdx != nil && showTransferAlert == false },
            set: { newValue in
                if !newValue {
                    transferIdx = nil
                    draftMemoText = ""
                }
            }
        )
    }

    // MARK: - Derived
    private var hasAnySelected: Bool {
        memoItems.contains(where: { $0.isDone })
    }

    // MARK: - Intent
    private func toggleAllSelected() {
        selectAll.toggle()
        for idx in memoItems.indices {
            memoItems[idx].isDone = selectAll
        }
    }

    private func toggleItem(_ item: MemoItem) {
        if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
            memoItems[idx].isDone.toggle()
        }
    }

    private func beginRename(_ item: MemoItem) {
        if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
            draftMemoText = memoItems[idx].text
            transferIdx = idx
        }
    }

    private func beginTransfer(_ item: MemoItem) {
        showTransferAlert = true
        if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
            transferIdx = idx
        }
    }

    private func beginDelete(_ item: MemoItem) {
        showDeleteAlert = true
        if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
            deleteIdx = idx
        }
    }

    private func loadFolder() {
        if let idx = folderIndex {
            memoItems = folders[idx].memos
        }
    }

    private func addDraftMemo() {
        let trimmed = draftMemoText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            memoItems.append(MemoItem(text: trimmed))
            draftMemoText = ""
        }
    }
}

// MARK: - Subviews
private struct SectionHeader: View {
    @Binding var selectAll: Bool
    let hasAnySelected: Bool
    let onToggleAll: () -> Void
    let onDeleteSelected: () -> Void
    init(selectAll: Binding<Bool>, hasAnySelected: Bool, onToggleAll: @escaping () -> Void, onDeleteSelected: @escaping () -> Void) {
        self._selectAll = selectAll
        self.hasAnySelected = hasAnySelected
        self.onToggleAll = onToggleAll
        self.onDeleteSelected = onDeleteSelected
    }

    var body: some View {
        HStack {
            Button(action: onToggleAll) {
                Image(systemName: selectAll ? "checkmark.square" : "square")
            }
            .buttonStyle(PlainButtonStyle())
            Text(selectAll ? "전체 선택 해제" : "전체 선택")

            Button(action: onDeleteSelected) {
                HStack {
                    Image(systemName: "trash")
                    Text("선택 삭제")
                }
            }
            .disabled(!hasAnySelected)
            .buttonStyle(BorderlessButtonStyle())
            .padding(.leading, 8)

            Spacer()
        }
        .padding(.horizontal)
    }
}

private struct MemoRow: View {
    let item: MemoItem
    let onToggle: () -> Void
    let onRename: () -> Void
    let onTransfer: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.square" : "square")
            }
            .buttonStyle(PlainButtonStyle())

            Text(item.text)
                .strikethrough(item.isDone, color: .gray)
                .contextMenu {
                    Button("이름 변경", action: onRename)
                    Button("삭제", role: .destructive, action: onDelete)
                }
            Spacer()

            Button(action: onTransfer) {
                Image(systemName: "cart")
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 4)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

private struct DraftRow: View {
    @Binding var text: String
    @FocusState.Binding var focused: Bool
    let onCommit: () -> Void

    var body: some View {
        HStack {
            TextField("새 메모 입력", text: $text)
                .focused($focused)
                .onSubmit(onCommit)
                .onChange(of: focused) { isFocused in
                    if isFocused == false {
                        onCommit()
                    }
                }
            Spacer()
            Button(action: onCommit) {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

private struct RenameSheet: View {
    let title: String
    @Binding var text: String
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.headline)
            TextField("새 이름", text: $text)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("취소", role: .cancel, action: onCancel)
                Spacer()
                Button("완료", action: onDone)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .presentationDetents([.medium])
    }
}

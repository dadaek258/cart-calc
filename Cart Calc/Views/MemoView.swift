//
//  MemoView.swift
//  Cart Calc
//
//  Created by 이다은 on 1/15/26.
//


import SwiftUI

struct MemoView: View {
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

    var body: some View {
        VStack {
            List {
                Section(header:
                    HStack {
                        Button(action: {
                            selectAll.toggle()
                            for idx in memoItems.indices {
                                memoItems[idx].isDone = selectAll
                            }
                        }) {
                            Image(systemName: selectAll ? "checkmark.square" : "square")
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text(selectAll ? "전체 선택 해제" : "전체 선택")

                        Button(action: {
                            showSelectedDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("선택 삭제")
                            }
                        }
                        .disabled(!memoItems.contains(where: { $0.isDone }))
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.leading, 8)

                        Spacer()
                    }
                    .padding(.horizontal)
                ) {
                    ForEach(memoItems) { item in
                        HStack {
                            Button(action: {
                                if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
                                    memoItems[idx].isDone.toggle()
                                }
                            }) {
                                Image(systemName: item.isDone ? "checkmark.square" : "square")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(item.text)
                                .strikethrough(item.isDone, color: .gray)
                            Spacer()
                            
                            Button(action: {
                                showTransferAlert = true
                                if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
                                    transferIdx = idx
                                }
                            }) {
                                Image(systemName: "cart")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 4)
                            
                            Button(action: {
                                showDeleteAlert = true
                                if let idx = memoItems.firstIndex(where: { $0.id == item.id }) {
                                    deleteIdx = idx
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    HStack {
                        TextField("새 메모 입력", text: $draftMemoText)
                            .focused($draftFieldFocused)
                            .onSubmit {
                                addDraftMemo()
                            }
                            .onChange(of: draftFieldFocused) { focused in
                                if !focused {
                                    addDraftMemo()
                                }
                            }
                        Spacer()
                        Button(action: { addDraftMemo() }) {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                                .foregroundColor(draftMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                        }
                        .disabled(draftMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .onChange(of: memoItems.map { $0.isDone }) { newValues in
            if newValues.isEmpty {
                selectAll = false
            } else {
                selectAll = newValues.allSatisfy { $0 }
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
    }

    private func addDraftMemo() {
        let trimmed = draftMemoText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            memoItems.append(MemoItem(text: trimmed))
            draftMemoText = ""
        }
    }
}
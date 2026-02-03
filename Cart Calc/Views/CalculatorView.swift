//
//  CalculatorView.swift
//  Cart Calc
//
//  Created by 이다은 on 1/15/26.
//


import SwiftUI
import PhotosUI

struct CalculatorView: View {
    @Binding var transferItemText: String?
    
    @State private var inputName: String = ""
    @State private var inputPrice: String = ""
    @State private var inputDiscount: String = ""
    @State private var items: [Item] = []
    @State private var selectAll: Bool = false
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var ocrImage: UIImage? = nil
    
    @State private var showDeleteAlert: Bool = false
    @State private var deleteIndex: Int? = nil
    @State private var showClearAlert: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var containerMinY: CGFloat = 0
    @State private var contentMinY: CGFloat = 0

    var total: Int {
        var sum = 0
        for item in items {
            sum += item.price * item.quantity
        }
        return sum
    }

    var selectedTotal: Int {
        var sum = 0
        for item in items where item.isChecked {
            sum += item.price * item.quantity
        }
        return sum
    }

    private var formattedSelectedTotal: String {
        let value: Int = selectedTotal
        return formatWon(value)
    }

    private var shouldShowNavTotal: Bool {
        scrollOffset > 8
    }
    
    @ViewBuilder
    private var principalTotalView: some View {
        VStack(spacing: 0) {
            Text("총 금액")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formattedSelectedTotal)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
    
    private func itemRowView(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Button(action: {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].isChecked.toggle()
                    }
                }) {
                    Image(systemName: item.isChecked ? "checkmark.square" : "square")
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))

                Text(item.name)
                    .font(.headline)
                    .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))
                    .strikethrough(!item.isChecked, color: .gray.opacity(0.6))

                Spacer()

                Button {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        if items[idx].quantity > 1 { items[idx].quantity -= 1 }
                    }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(item.isChecked ? .blue : .gray.opacity(0.6))

                Text("\(item.quantity)")
                    .font(.subheadline)
                    .frame(minWidth: 24)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(Color(.systemGray5)))
                    .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))

                Button {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].quantity += 1
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(item.isChecked ? .blue : .gray.opacity(0.6))

                Button {
                    showDeleteAlert = true
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        deleteIndex = idx
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(item.isChecked ? .red : .gray.opacity(0.6))
                        .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            HStack(spacing: 4) {
                if item.discount > 0 {
                    Text("₩\(Int(round(Double(item.price) * 100.0 / Double(100 - item.discount))))")
                        .foregroundColor(.gray.opacity(0.6))
                        .strikethrough(true, color: .gray.opacity(0.6))
                        .font(.subheadline)

                    Text("₩\(item.price)")
                        .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))
                        .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                } else {
                    Text("₩\(item.price)")
                        .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))
                        .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                }
            }
            if item.discount > 0 {
                Text("\(item.discount)% 할인 적용")
                    .foregroundColor(item.isChecked ? .red : .gray.opacity(0.6))
                    .font(.caption)
                    .padding(.top, 2)
                    .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    @ViewBuilder
    private var totalSummarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("총 금액")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(formattedSelectedTotal)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var inputSection: some View {
        HStack(alignment: .bottom) {
            TextField("품명 입력", text: $inputName)
            VStack(alignment: .leading, spacing: 2) {
                TextField("가격 입력", text: $inputPrice)
                    .keyboardType(.numberPad)
                    .onChange(of: inputPrice) { oldValue, newValue in
                        handlePriceChange(newValue)
                    }
            }
            HStack(spacing: 2) {
                TextField("할인율", text: $inputDiscount)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                Text("%")
            }
            Button("추가", action: addItemFromInput)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var selectAllSection: some View {
        HStack {
            Button(action: toggleAllSelected) {
                Image(systemName: selectAll ? "checkmark.square" : "square")
            }
            .buttonStyle(PlainButtonStyle())
            Text(selectAll ? "전체 선택 해제" : "전체 선택")
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var itemsSection: some View {
        ForEach(items) { item in
            itemRowView(for: item)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ContentMinYKey.self,
                        value: proxy.frame(in: .global).minY
                    )
                }
                .frame(height: 1)

                totalSummarySection
                inputSection
                selectAllSection
                itemsSection

                Color.clear
                    .frame(height: 12)
            }
            .padding(.top, 4)
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ContainerMinYKey.self,
                    value: proxy.frame(in: .global).minY
                )
            }
        )
        .onPreferenceChange(ContentMinYKey.self) { value in
            contentMinY = value
            scrollOffset = containerMinY - contentMinY
        }
        .onPreferenceChange(ContainerMinYKey.self) { value in
            containerMinY = value
            scrollOffset = containerMinY - contentMinY
        }
        .onChange(of: items.map { $0.isChecked }) { newValues in
            if newValues.isEmpty {
                selectAll = false
            } else {
                selectAll = newValues.allSatisfy { $0 }
            }
        }
        .navigationTitle(shouldShowNavTotal ? " " : "장바구니 계산기")
        .navigationBarTitleDisplayMode(shouldShowNavTotal ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if shouldShowNavTotal {
                    principalTotalView
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Image(systemName: "camera")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("사진 찍기/선택")
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(Color(.systemGray5))
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        guard let newItem = newValue else { return }
                        newItem.loadTransferable(type: Data.self) { result in
                            switch result {
                            case .success(let data?):
                                if let uiImage = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.ocrImage = uiImage
                                        OCRTextRecognizer.recognizeText(from: uiImage) { foundName, foundPrice in
                                            if let foundName = foundName {
                                                self.inputName = foundName
                                            }
                                            if let foundPrice = foundPrice {
                                                let formatter = NumberFormatter()
                                                formatter.numberStyle = .decimal
                                                if let formattedPrice = formatter.string(from: NSNumber(value: foundPrice)) {
                                                    self.inputPrice = formattedPrice
                                                } else {
                                                    self.inputPrice = String(foundPrice)
                                                }
                                            }
                                        }
                                    }
                                }
                            default:
                                break
                            }
                        }
                    }

                Button {
                    showClearAlert = true
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("장보기 완료")
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color(.systemGray5))
            }
        }
        .alert("삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) {
                if let idx = deleteIndex {
                    items.remove(at: idx)
                }
                deleteIndex = nil
            }
        } message: {
            Text("선택한 품목을 삭제합니다.")
        }
        .alert("장바구니를 비우시겠습니까?", isPresented: $showClearAlert) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) { items.removeAll() }
        } message: {
            Text("장바구니 목록이 모두 삭제됩니다.")
        }
        .onChange(of: transferItemText) { newValue in
            if let text = newValue {
                inputName = text
                transferItemText = nil
            }
        }
    }

    private func handlePriceChange(_ newValue: String) {
        let raw = newValue.replacingOccurrences(of: ",", with: "")
        guard let intVal = Int(raw) else {
            inputPrice = ""
            return
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let formatted = formatter.string(from: NSNumber(value: intVal)) {
            if formatted != inputPrice {
                inputPrice = formatted
            }
        }
    }

    private func addItemFromInput() {
        let rawPrice = inputPrice.replacingOccurrences(of: ",", with: "")
        if let price = Int(rawPrice), !inputName.isEmpty {
            let discount: Double
            if let discountInput = Double(inputDiscount), (0...100).contains(discountInput) {
                discount = discountInput
            } else {
                discount = 0
            }
            let discountedPrice = Int(round(Double(price) * (100 - discount) / 100))
            items.append(Item(name: inputName, price: discountedPrice, discount: Int(round(discount)), quantity: 1, isChecked: true))
            inputName = ""
            inputPrice = ""
            inputDiscount = ""
        }
    }

    private func toggleAllSelected() {
        selectAll.toggle()
        for idx in items.indices {
            items[idx].isChecked = selectAll
        }
    }

    private func formatWon(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(formatted)"
    }
}

private struct ContentMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ContainerMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


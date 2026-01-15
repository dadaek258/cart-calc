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

    var total: Int { items.map { $0.price * $0.quantity }.reduce(0, +) }
    var selectedTotal: Int { items.filter { $0.isChecked }.map { $0.price * $0.quantity }.reduce(0, +) }

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()) {
                    Text("사진 찍기/선택")
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .onChange(of: selectedPhoto) { newItem in
                    guard let newItem else { return }
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
            
            HStack(alignment: .bottom) {
                TextField("품명 입력", text: $inputName)
                VStack(alignment: .leading, spacing: 2) {
                    TextField("가격 입력", text: $inputPrice)
                        .keyboardType(.numberPad)
                        .onChange(of: inputPrice) { newValue in
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
                }
                HStack(spacing: 2) {
                    TextField("할인율", text: $inputDiscount)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                    Text("%")
                }
                Button("추가") {
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
            }
            .padding()
            
            HStack {
                Button(action: {
                    selectAll.toggle()
                    for idx in items.indices {
                        items[idx].isChecked = selectAll
                    }
                }) {
                    Image(systemName: selectAll ? "checkmark.square" : "square")
                }
                .buttonStyle(PlainButtonStyle())
                Text(selectAll ? "전체 선택 해제" : "전체 선택")
                Spacer()
            }
            .padding(.horizontal)
            
            List {
                ForEach(items) { item in
                    VStack(alignment: .leading) {
                        HStack {
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
                                .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))
                                .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                            
                            Spacer()
                            
                            Button("-") {
                                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                    if items[idx].quantity > 1 { items[idx].quantity -= 1 }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(item.isChecked ? .blue : .gray.opacity(0.6))
                            .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                            
                            Text("\(item.quantity)")
                                .frame(width: 30)
                                .foregroundColor(item.isChecked ? .primary : .gray.opacity(0.6))
                                .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                            
                            Button("+") {
                                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                    items[idx].quantity += 1
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(item.isChecked ? .blue : .gray.opacity(0.6))
                            .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                            
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
                            Text("\(item.discount)%할인적용")
                                .foregroundColor(item.isChecked ? .red : .gray.opacity(0.6))
                                .font(.caption)
                                .padding(.top, 2)
                                .strikethrough(!item.isChecked, color: .gray.opacity(0.6))
                        }
                    }
                }
            }
            .onChange(of: items.map { $0.isChecked }) { newValues in
                if newValues.isEmpty {
                    selectAll = false
                } else {
                    selectAll = newValues.allSatisfy { $0 }
                }
            }
            
            Text("선택 품목 합계: ₩\(selectedTotal)")
                .font(.title2)
                .padding(.bottom)
            
            Button("장보기 완료") {
                showClearAlert = true
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(8)
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
}
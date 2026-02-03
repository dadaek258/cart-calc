import SwiftUI

struct ComparisonView: View {
    @State private var products: [Product] = [Product()]
    @State private var sortedProducts: [Product] = []
    let unitOptions = ["g", "kg", "ml", "l"]

    struct Product: Identifiable {
        let id = UUID()
        var name: String = ""
        var price: String = ""
        var quantity: String = ""
        var unit: String = "g"
        var priceValue: Double? { Double(price.replacingOccurrences(of: ",", with: "")) }
        var quantityValue: Double? { Double(quantity.replacingOccurrences(of: ",", with: "")) }
        var realUnitPrice: Double? {
            guard let price = priceValue, let qty = quantityValue, qty > 0 else { return nil }
            switch unit {
            case "g": return price / qty
            case "kg": return price / (qty * 1000)
            case "ml": return price / qty
            case "l": return price / (qty * 1000)
            default: return nil
            }
        }
        var baseUnit: String {
            switch unit {
            case "g", "kg": return "g"
            case "ml", "l": return "ml"
            default: return ""
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("단위가격 비교")
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // Header row
            HStack(spacing: 0) {
                Text("제품명")
                    .font(.headline)
                    .frame(maxWidth: 130, alignment: .leading)
                Text("수량")
                    .font(.headline)
                    .frame(width: 70, alignment: .center)
                Text("단위(g)")
                    .font(.headline)
                    .frame(width: 60, alignment: .center)
                Text("가격(원)")
                    .font(.headline)
                    .frame(width: 85, alignment: .trailing)
            }
            .padding(.horizontal, 8)

            List {
                ForEach(products.indices, id: \.self) { idx in
                    HStack(spacing: 0) {
                        TextField("제품명", text: $products[idx].name)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 130, alignment: .leading)

                        TextField("수량", text: $products[idx].quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70, alignment: .center)

                        Picker("", selection: $products[idx].unit) {
                            ForEach(unitOptions, id: \.self) { unit in
                                Text(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60, alignment: .center)

                        TextField("가격", text: $products[idx].price)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 85, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indices in
                    products.remove(atOffsets: indices)
                }
            }
            .frame(maxHeight: 260)
            .listStyle(PlainListStyle())
            .padding(.horizontal, -16)

            Button(action: {
                products.append(Product())
            }) {
                Text("+ 추가하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                sortedProducts = products
                    .filter { $0.realUnitPrice != nil && !$0.name.isEmpty }
                    .sorted { ($0.realUnitPrice ?? .greatestFiniteMagnitude) < ($1.realUnitPrice ?? .greatestFiniteMagnitude) }
            }) {
                Text("단위가격 비교하기")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(products.allSatisfy { $0.name.isEmpty || $0.realUnitPrice == nil })

            if !sortedProducts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedProducts) { product in
                        HStack {
                            Text(product.name)
                                .fontWeight(.semibold)
                            Spacer()
                            if let price = product.realUnitPrice {
                                Text("₩\(price, specifier: "%.2f")/\(product.baseUnit)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            Button(action: {
                products = [Product()]
                sortedProducts = []
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("새로고침")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .foregroundColor(Color.blue)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

#Preview {
    ComparisonView()
}

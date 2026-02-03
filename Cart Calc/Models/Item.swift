//
//  Item.swift
//  Cart Calc
//
//  Created by 이다은 on 1/15/26.
//


import Foundation

struct Item: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let discount: Int
    var quantity: Int = 1
    var isChecked: Bool = false
}
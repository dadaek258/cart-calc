//
//  MemoItem.swift
//  Cart Calc
//
//  Created by 이다은 on 1/15/26.
//


import Foundation

struct MemoItem: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var isDone: Bool = false
}
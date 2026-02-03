//
//  ContentView.swift
//  Cart Calc
//
//  Created by 이다은 on 1/10/26.
//
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 1
    @State private var transferItemText: String? = nil

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FolderListView()
            }
            .tabItem {
                Image(systemName: "note.text")
                Text("메모")
            }
            .tag(0)

            NavigationStack {
                CalculatorView(transferItemText: $transferItemText)
            }
            .tabItem {
                Image(systemName: "cart")
                Text("계산기")
            }
            .tag(1)
            
            ComparisonView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("비교")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}

//
//  CreationItem.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-20.
//

import SwiftUI

struct CreationItem: Identifiable, Hashable {
    let id = UUID()
    let topic: String
    let quality: String
    let path: URL
    let createdDate: Date
}

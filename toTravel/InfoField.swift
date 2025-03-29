//
//  InfoField.swift
//  toTravel
//
//  Created by Ed on 3/24/25.
//

import SwiftUI

struct InfoField: View {
    let label: String
    let value: String
    var valueColor: Color = .black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
        }
    }
}

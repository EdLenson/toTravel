//
//  Preferences.swift
//  toTravel
//
//  Created by Ed on 3/25/25.
//

import SwiftUI

struct TitleOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

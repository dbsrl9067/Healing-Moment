//
//  HealingWidgetBundle.swift
//  HealingWidget
//
//  Created by 김윤기 on 3/13/26.
//

import WidgetKit
import SwiftUI

@main
struct HealingWidgetBundle: WidgetBundle {
    var body: some Widget {
        HealingWidget()
        HealingWidgetControl()
        HealingWidgetLiveActivity()
    }
}

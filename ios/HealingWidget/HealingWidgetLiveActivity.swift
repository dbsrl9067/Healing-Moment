//
//  HealingWidgetLiveActivity.swift
//  HealingWidget
//
//  Created by 김윤기 on 3/13/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HealingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HealingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HealingWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HealingWidgetAttributes {
    fileprivate static var preview: HealingWidgetAttributes {
        HealingWidgetAttributes(name: "World")
    }
}

extension HealingWidgetAttributes.ContentState {
    fileprivate static var smiley: HealingWidgetAttributes.ContentState {
        HealingWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HealingWidgetAttributes.ContentState {
         HealingWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HealingWidgetAttributes.preview) {
   HealingWidgetLiveActivity()
} contentStates: {
    HealingWidgetAttributes.ContentState.smiley
    HealingWidgetAttributes.ContentState.starEyes
}

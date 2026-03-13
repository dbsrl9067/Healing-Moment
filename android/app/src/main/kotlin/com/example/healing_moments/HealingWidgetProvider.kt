package com.example.healing_moments

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HealingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // 1. Flutter(home_widget)에서 저장한 데이터 불러오기
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // 2. 레이아웃에 데이터 주입
            val views = RemoteViews(context.packageName, R.layout.healing_widget).apply {
                // 저장된 명언 불러오기 (없으면 기본값 설정)
                val quote = widgetData.getString("healing_quote", "당신은 빛나는 존재입니다.")
                val author = widgetData.getString("healing_author", "힐링 모먼트")
                
                setTextViewText(R.id.appwidget_text, quote)
                setTextViewText(R.id.appwidget_author, "- $author")
            }

            // 3. 위젯 갱신
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

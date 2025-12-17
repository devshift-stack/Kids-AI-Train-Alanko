package com.alanko.ai.alanko_ai

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AlankoWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.alanko_widget)

            val childName = widgetData.getString("child_name", "Kind") ?: "Kind"
            val streak = widgetData.getInt("current_streak", 0)
            val lessons = widgetData.getInt("lessons_today", 0)
            val badges = widgetData.getInt("total_badges", 0)

            views.setTextViewText(R.id.child_name, "Hallo $childName!")
            views.setTextViewText(R.id.streak_value, streak.toString())
            views.setTextViewText(R.id.lessons_value, lessons.toString())
            views.setTextViewText(R.id.badges_value, badges.toString())

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

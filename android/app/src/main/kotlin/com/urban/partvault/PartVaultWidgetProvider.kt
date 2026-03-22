package com.urban.partvault

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

class PartVaultWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val recentItem = widgetData.getString("widget_recent_item", "Nessun oggetto")
            val recentCode = widgetData.getString("widget_recent_code", "")
            val itemCount = widgetData.getInt("widget_item_count", 0)

            val views = RemoteViews(context.packageName, R.layout.partvault_widget)
            views.setTextViewText(R.id.widget_recent_name, recentItem ?: "Nessun oggetto")
            views.setTextViewText(R.id.widget_item_count, "$itemCount oggetti")

            if (!recentCode.isNullOrEmpty()) {
                views.setTextViewText(R.id.widget_recent_code, recentCode)
            } else {
                views.setTextViewText(R.id.widget_recent_code, "")
            }

            // Tap to open app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

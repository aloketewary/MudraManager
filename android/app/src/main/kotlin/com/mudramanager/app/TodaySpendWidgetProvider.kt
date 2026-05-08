package com.mudramanager.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TodaySpendWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_spend_widget)

            val widgetData = HomeWidgetPlugin.getData(context)
            views.setTextViewText(R.id.today_spend_amount, widgetData.getString("todayExpense", "₹0"))

            val budgetRemaining = widgetData.getString("budgetRemaining", "") ?: ""
            if (budgetRemaining.isNotEmpty()) {
                views.setViewVisibility(R.id.budget_section, View.VISIBLE)
                views.setTextViewText(R.id.budget_remaining_text, budgetRemaining)
            } else {
                views.setViewVisibility(R.id.budget_section, View.GONE)
            }

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val openPending = PendingIntent.getActivity(
                context, 3, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.today_spend_root, openPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

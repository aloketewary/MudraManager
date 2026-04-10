package com.mudramanager.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class BalanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget)

            val widgetData = HomeWidgetPlugin.getData(context)
            views.setTextViewText(R.id.widget_balance, widgetData.getString("balance", "₹0"))
            views.setTextViewText(R.id.widget_expense, widgetData.getString("todayExpense", "₹0"))
            views.setTextViewText(R.id.widget_income, widgetData.getString("todayIncome", "₹0"))

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val openPending = PendingIntent.getActivity(
                context, 2, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

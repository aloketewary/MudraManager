package com.ghostwork.app.mudra_manager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class QuickAddWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
            
            val widgetData = HomeWidgetPlugin.getData(context)
            val balance = widgetData.getString("balance", "₹0")
            val expense = widgetData.getString("todayExpense", "₹0")
            val income = widgetData.getString("todayIncome", "₹0")
            
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_expense, expense)
            views.setTextViewText(R.id.widget_income, income)
            
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "add_transaction"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(context, appWidgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

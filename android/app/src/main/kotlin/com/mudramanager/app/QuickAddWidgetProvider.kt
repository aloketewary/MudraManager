package com.mudramanager.app

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
            
            val intent = Intent(context, MainActivity::class.java)
            intent.putExtra("widget_action", "add_transaction")
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

package com.example.showtracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ProssimamenteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_prossimamente).apply {
                // Card 1
                val imagePath1 = widgetData.getString("upcoming_1_image", "")
                if (imagePath1?.isNotEmpty() == true) {
                    val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath1)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.img_poster_1, bitmap)
                    }
                }

                val title1 = widgetData.getString("upcoming_1_title", "Nessuna uscita")
                setTextViewText(R.id.tv_title_1, title1)
                setTextViewText(R.id.tv_se_1, widgetData.getString("upcoming_1_se", ""))
                setTextViewText(R.id.tv_countdown_1, widgetData.getString("upcoming_1_countdown", ""))
                setTextViewText(R.id.tv_date_1, widgetData.getString("upcoming_1_date", ""))
                
                // Deep Link Card 1
                val id1 = widgetData.getString("upcoming_1_id", "")
                if (id1?.isNotEmpty() == true) {
                    val intent1 = Intent(context, MainActivity::class.java).apply {
                        data = Uri.parse("showtracker:///series/detail/$id1")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    val pendingIntent1 = PendingIntent.getActivity(context, 1, intent1, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    setOnClickPendingIntent(R.id.card_1, pendingIntent1)
                }
                
                // Card 2
                val imagePath2 = widgetData.getString("upcoming_2_image", "")
                if (imagePath2?.isNotEmpty() == true) {
                    val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath2)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.img_poster_2, bitmap)
                    }
                }

                val title2 = widgetData.getString("upcoming_2_title", "")
                setTextViewText(R.id.tv_title_2, title2)
                setTextViewText(R.id.tv_se_2, widgetData.getString("upcoming_2_se", ""))
                setTextViewText(R.id.tv_countdown_2, widgetData.getString("upcoming_2_countdown", ""))
                setTextViewText(R.id.tv_date_2, widgetData.getString("upcoming_2_date", ""))
                
                // Deep Link Card 2
                val id2 = widgetData.getString("upcoming_2_id", "")
                if (id2?.isNotEmpty() == true) {
                    val intent2 = Intent(context, MainActivity::class.java).apply {
                        data = Uri.parse("showtracker:///series/detail/$id2")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    val pendingIntent2 = PendingIntent.getActivity(context, 2, intent2, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    setOnClickPendingIntent(R.id.card_2, pendingIntent2)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

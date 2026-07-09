package com.example.showtracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class MaratonaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_maratona).apply {
                
                val title = widgetData.getString("marathon_title", "Tutto in pari!")
                val episodeInfo = widgetData.getString("marathon_episode_title", "Ottimo lavoro.")
                val showId = widgetData.getString("marathon_show_id", "")

                setTextViewText(R.id.tv_marathon_title, title)
                setTextViewText(R.id.tv_marathon_episode, episodeInfo)

                val imagePath = widgetData.getString("marathon_image", "")
                if (imagePath?.isNotEmpty() == true) {
                    val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.img_poster_marathon, bitmap)
                    }
                }

                // Interazione: Apri l'app sul contenitore (Pagina di dettaglio)
                if (showId?.isNotEmpty() == true) {
                    val appIntent = Intent(context, MainActivity::class.java).apply {
                        data = Uri.parse("showtracker:///series/detail/$showId")
                    }
                    val pendingAppIntent = PendingIntent.getActivity(context, 0, appIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    setOnClickPendingIntent(R.id.maratona_container, pendingAppIntent)
                }

                // Interazione Freccia: Apri la homepage delle serie
                val homeIntent = Intent(context, MainActivity::class.java).apply {
                    data = Uri.parse("showtracker:///series")
                }
                val pendingHomeIntent = PendingIntent.getActivity(context, 100, homeIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.btn_open_show, pendingHomeIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

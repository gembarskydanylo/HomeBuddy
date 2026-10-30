package app.homebuddy.home_buddy

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class CholeraWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.cholera_widget)
            views.setOnClickPendingIntent(R.id.add_task, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("homebuddy://capture")))
            manager.updateAppWidget(id, views)
        }
    }
}

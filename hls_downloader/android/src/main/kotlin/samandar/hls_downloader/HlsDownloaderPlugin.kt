package samandar.hls_downloader

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.media3.common.MediaItem
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.database.ExoDatabaseProvider
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadHelper
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.media3.exoplayer.upstream.cache.Cache
import androidx.media3.exoplayer.upstream.cache.NoOpCacheEvictor
import androidx.media3.exoplayer.upstream.cache.SimpleCache
import kotlinx.coroutines.*
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

// ---------------------------------------------------------------------
// EventChannel handler for a single download id
private class ProgressStreamHandler : EventChannel.StreamHandler {
    var sink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
    override fun onCancel(arguments: Any?) { sink = null }
}

private fun EventChannel.EventSink.endOfStream() {
    try { success(null) } catch (_: Exception) { }
}
// ---------------------------------------------------------------------

/** Native HLS downloader plugin (Android – Media3/ExoPlayer) */
class HlsDownloaderPlugin : FlutterPlugin, MethodCallHandler {

    // Flutter channels
    private lateinit var channel: MethodChannel

    // Android & Media3
    private lateinit var appContext: Context
    private lateinit var downloadManager: DownloadManager
    private lateinit var downloadDir: File

    // Coroutine scope
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // Maps
    private val streamHandlers = mutableMapOf<String, ProgressStreamHandler>() // id -> handler
    private val localPaths = mutableMapOf<String, String>()                    // id -> final path

    // -------------------------------------------------------------------------
    // FlutterPlugin lifecycle
    // -------------------------------------------------------------------------
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "hls_downloader")
        channel.setMethodCallHandler(this)

        appContext = binding.applicationContext

        // Media3 cache & DownloadManager
        val dbProvider = ExoDatabaseProvider(appContext)
        downloadDir = File(appContext.getExternalFilesDir(null), "hls_cache").apply { mkdirs() }

        val cache: Cache = SimpleCache(downloadDir, NoOpCacheEvictor(), dbProvider)
        downloadManager = DownloadManager(
            appContext,
            dbProvider,
            cache,
            DefaultHttpDataSource.Factory(),
            Executors.newFixedThreadPool(2)
        )

        // Listener to push progress to Flutter
        val mainHandler = Handler(Looper.getMainLooper())
        downloadManager.addListener(object : DownloadManager.Listener {
            override fun onDownloadChanged(
                manager: DownloadManager,
                download: Download,
                finalException: java.lang.Exception?
            ) {
                val id = download.request.id
                streamHandlers[id]?.sink?.let { sink ->
                    val percent = when {
                        download.state == Download.STATE_COMPLETED -> 1.0
                        download.percentDownloaded >= 0 -> download.percentDownloaded / 100.0
                        else -> 0.0
                    }
                    mainHandler.post {
                        sink.success(percent)
                        if (download.state == Download.STATE_FAILED) {
                            sink.error("DL_ERROR", "Download failed", finalException?.localizedMessage)
                        }
                        if (download.state == Download.STATE_COMPLETED) {
                            sink.endOfStream()
                        }
                    }
                }
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        scope.cancel()
        channel.setMethodCallHandler(null)
    }

    // -------------------------------------------------------------------------
    // MethodChannel handler
    // -------------------------------------------------------------------------
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startDownload" -> {
                val url = call.argument<String>("url")
                if (url == null) {
                    result.error("INVALID_URL", "Argument 'url' is required", null)
                    return
                }
                scope.launch {
                    try {
                        val id = startHlsDownload(url)
                        withContext(Dispatchers.Main) { result.success(id) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("DOWNLOAD_ERROR", e.localizedMessage, null)
                        }
                    }
                }
            }

            "localPath" -> {
                val id = call.argument<String>("id")
                result.success(localPaths[id])
            }

            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------
    private suspend fun startHlsDownload(url: String): String = withContext(Dispatchers.IO) {
        val id = UUID.randomUUID().toString()

        // Build MediaItem
        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(url))
            .setMediaId(id)
            .build()

        // Prepare the download request
        val helper = DownloadHelper.forMediaItem(appContext, mediaItem, DefaultHttpDataSource.Factory())
        helper.prepare()
        val request: DownloadRequest = helper.getDownloadRequest(id)

        // Add to DownloadManager
        downloadManager.addDownload(request)

        // Prepare EventChannel for progress
        val handler = ProgressStreamHandler()
        EventChannel(channel.binaryMessenger, "hls_downloader/progress_$id")
            .setStreamHandler(handler)
        streamHandlers[id] = handler

        // Save local path location (playlist will be produced on completion)
        localPaths[id] = File(downloadDir, id).absolutePath

        return@withContext id
    }
}

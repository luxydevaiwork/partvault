package com.urban.partvault

import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.Charset

class MainActivity : FlutterActivity() {

    private val nfcChannel = "com.urban.partvault/nfc"
    private var pendingNfcPayload: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nfcChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingNfcPayload" -> {
                        result.success(pendingNfcPayload)
                        pendingNfcPayload = null
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestHighRefreshRate()
        handleNfcIntent(intent)
    }

    private fun requestHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val display = display ?: return
            val modes = display.supportedModes
            val bestMode = modes.maxByOrNull { it.refreshRate } ?: return
            val params = window.attributes
            params.preferredDisplayModeId = bestMode.modeId
            window.attributes = params
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val params = window.attributes
            @Suppress("DEPRECATION")
            params.preferredRefreshRate = Float.MAX_VALUE
            window.attributes = params
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNfcIntent(intent)
    }

    private fun handleNfcIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        if (action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
            action == NfcAdapter.ACTION_TAG_DISCOVERED) {
            val tag: Tag? = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
            if (tag != null) {
                val ndef = Ndef.get(tag)
                if (ndef != null) {
                    try {
                        ndef.connect()
                        val message = ndef.ndefMessage
                        ndef.close()
                        if (message != null && message.records.isNotEmpty()) {
                            val record = message.records[0]
                            val payload = String(record.payload, Charset.forName("UTF-8"))
                            if (payload.contains("PV1|")) {
                                pendingNfcPayload = if (payload.startsWith("PV1|")) {
                                    payload
                                } else {
                                    payload.substring(1)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        // Ignore NFC read errors
                    }
                }
            }
        }
    }
}

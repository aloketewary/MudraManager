package com.mudramanager.app

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle

class MainActivity: FlutterFragmentActivity() {  // extend FragmentActivity
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // no need to call GeneratedPluginRegistrant if using v2 embedding
    }
}
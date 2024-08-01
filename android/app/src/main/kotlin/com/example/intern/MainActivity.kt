package com.example.intern

import android.os.Bundle
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FacebookSdk.sdkInitialize(getApplicationContext())
        AppEventsLogger.activateApp(application)
    }
}

package dev.adventcalendar.advent_calendar

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private var sink: EventChannel.EventSink? = null
    private val gravity = FloatArray(3)
    private var initialized = false
    private var listening = false
    private val sensors: SensorManager by lazy { getSystemService(SENSOR_SERVICE) as SensorManager }
    private val motionSensor: Sensor? by lazy {
        sensors.getDefaultSensor(Sensor.TYPE_GRAVITY)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "advent_calendar/tilt")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    sink = events
                    if (motionSensor == null) {
                        events.error("NO_SENSOR", "Kein Bewegungssensor verfügbar", null)
                    } else {
                        startSensor()
                    }
                }
                override fun onCancel(arguments: Any?) { stopSensor(); sink = null }
            })
    }

    private fun startSensor() {
        if (listening || sink == null) return
        initialized = false
        listening = sensors.registerListener(this, motionSensor, SensorManager.SENSOR_DELAY_GAME)
        if (!listening) sink?.error("SENSOR_UNAVAILABLE", "Bewegungssensor nicht verfügbar", null)
    }

    private fun stopSensor() { sensors.unregisterListener(this); listening = false }
    override fun onPause() { stopSensor(); super.onPause() }
    override fun onResume() { super.onResume(); if (motionSensor != null) startSensor() }
    override fun onDestroy() { stopSensor(); sink = null; super.onDestroy() }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    @Suppress("DEPRECATION")
    override fun onSensorChanged(event: SensorEvent) {
        for (i in 0..2) {
            gravity[i] = if (!initialized || event.sensor.type == Sensor.TYPE_GRAVITY) event.values[i]
                else gravity[i] * 0.85f + event.values[i] * 0.15f
        }
        initialized = true
        val x = gravity[0].toDouble() / SensorManager.GRAVITY_EARTH
        val y = gravity[1].toDouble() / SensorManager.GRAVITY_EARTH
        val tilt = when (windowManager.defaultDisplay.rotation) {
            Surface.ROTATION_90 -> listOf(y, x)
            Surface.ROTATION_180 -> listOf(x, -y)
            Surface.ROTATION_270 -> listOf(-y, -x)
            else -> listOf(-x, y)
        }
        sink?.success(tilt)
    }
}

package com.linkie.linkie_mo

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.linkie.app/timelapse"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "generateVideo") {
                val imagePaths = call.argument<List<String>>("imagePaths")
                val outputPath = call.argument<String>("outputPath")
                val width = call.argument<Int>("width") ?: 540
                val height = call.argument<Int>("height") ?: 960
                val fps = call.argument<Int>("fps") ?: 30

                if (imagePaths == null || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "Paths or output path is null", null)
                    return@setMethodCallHandler
                }

                thread(start = true) {
                    try {
                        val success = buildVideo(imagePaths, outputPath, width, height, fps)
                        runOnUiThread {
                            result.success(success)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        runOnUiThread {
                            result.error("ENCODER_ERROR", e.message, null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun buildVideo(imagePaths: List<String>, outputPath: String, width: Int, height: Int, fps: Int): Boolean {
        val outputFile = File(outputPath)
        if (outputFile.exists()) {
            outputFile.delete()
        }

        var codec: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var muxerStarted = false
        var trackIndex = -1

        try {
            codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
            format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar)
            format.setInteger(MediaFormat.KEY_BIT_RATE, 3000000) // 3 Mbps
            format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)

            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            codec.start()

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            val bufferInfo = MediaCodec.BufferInfo()
            val durationUsPerFrame = 1000000L / fps
            var presentationTimeUs = 0L

            for (i in imagePaths.indices) {
                val path = imagePaths[i]
                val bitmap = BitmapFactory.decodeFile(path) ?: continue
                val resizedBitmap = if (bitmap.width != width || bitmap.height != height) {
                    Bitmap.createScaledBitmap(bitmap, width, height, true)
                } else {
                    bitmap
                }

                val yuvBytes = getYCbCrFromRGB(resizedBitmap, width, height)

                if (resizedBitmap != bitmap) {
                    resizedBitmap.recycle()
                }
                bitmap.recycle()

                // Feed input buffer
                var inputBufferIndex = codec.dequeueInputBuffer(20000)
                while (inputBufferIndex < 0) {
                    Thread.sleep(5)
                    inputBufferIndex = codec.dequeueInputBuffer(20000)
                }

                val inputBuffer = codec.getInputBuffer(inputBufferIndex)!!
                inputBuffer.clear()
                inputBuffer.put(yuvBytes)

                val isLast = i == imagePaths.size - 1
                codec.queueInputBuffer(
                    inputBufferIndex,
                    0,
                    yuvBytes.size,
                    presentationTimeUs,
                    if (isLast) MediaCodec.BUFFER_FLAG_END_OF_STREAM else 0
                )

                presentationTimeUs += durationUsPerFrame

                // Drain output buffer
                while (true) {
                    val outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                    if (outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        break
                    } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        val newFormat = codec.outputFormat
                        trackIndex = muxer.addTrack(newFormat)
                        muxer.start()
                        muxerStarted = true
                    } else if (outputBufferIndex >= 0) {
                        val outputBuffer = codec.getOutputBuffer(outputBufferIndex)!!
                        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                            bufferInfo.size = 0
                        }

                        if (bufferInfo.size != 0 && muxerStarted) {
                            outputBuffer.position(bufferInfo.offset)
                            outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                        }

                        codec.releaseOutputBuffer(outputBufferIndex, false)

                        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            break
                        }
                    }
                }
            }

            // Flush encoder
            var isEosReached = false
            var retries = 0
            while (!isEosReached && retries < 20) {
                val outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                if (outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                    retries++
                    Thread.sleep(5)
                } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    if (!muxerStarted) {
                        trackIndex = muxer.addTrack(codec.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                } else if (outputBufferIndex >= 0) {
                    val outputBuffer = codec.getOutputBuffer(outputBufferIndex)!!
                    if (bufferInfo.size != 0 && muxerStarted) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                    }
                    codec.releaseOutputBuffer(outputBufferIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        isEosReached = true
                    }
                }
            }

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        } finally {
            try {
                codec?.stop()
                codec?.release()
            } catch (_: Exception) {}
            try {
                if (muxerStarted) {
                    muxer?.stop()
                }
                muxer?.release()
            } catch (_: Exception) {}
        }
    }

    private fun getYCbCrFromRGB(bitmap: Bitmap, width: Int, height: Int): ByteArray {
        val size = width * height
        val bytes = ByteArray(size * 3 / 2)
        val argb = IntArray(size)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        var yIndex = 0
        var uvIndex = size

        for (j in 0 until height) {
            for (i in 0 until width) {
                val index = j * width + i
                val r = (argb[index] shr 16) and 0xff
                val g = (argb[index] shr 8) and 0xff
                val b = argb[index] and 0xff

                var y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                var u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                var v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128

                y = Math.max(0, Math.min(y, 255))
                u = Math.max(0, Math.min(u, 255))
                v = Math.max(0, Math.min(v, 255))

                bytes[yIndex++] = y.toByte()

                if (j % 2 == 0 && i % 2 == 0) {
                    bytes[uvIndex++] = v.toByte()
                    bytes[uvIndex++] = u.toByte()
                }
            }
        }
        return bytes
    }
}

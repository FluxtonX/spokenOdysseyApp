package com.spokenodyssey.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Turns files downloaded from the glasses into normal, playable media.
 *
 * The glasses send each capture as one extension-less file, e.g. `photo-20261118050337005`,
 * that packs several files back to back followed by an index:
 *
 *   [media bytes][gyro-….txt][frame-….txt] … [entry × count][8 hex count]"Thisadir"
 *
 * Each index entry is a fixed-width record (40 bytes on current firmware): the file name
 * followed by its size in hex, zero-padded to fill the record. The sizes plus the index add up
 * exactly to the file length, which is how the record width is verified.
 *
 * The media (jpg / mp4 / opus) is the first entry and starts at byte 0. This class extracts
 * it to `<name>.<ext>`, validates it, creates a video cover image and removes the bundle.
 */
object GlassesMediaUnpacker {

    const val TYPE_IMAGE = 1
    const val TYPE_VIDEO = 2
    const val TYPE_AUDIO = 3

    private const val MAGIC = "Thisadir"
    private const val THUMB_DIR = ".thumbs"
    private val MEDIA_EXT = setOf("jpg", "jpeg", "png", "mp4", "avi", "mov", "opus", "ogg", "wav")
    private val IGNORED_EXT = setOf("txt", "log", "config", "json", "pcm", "tmp")
    // Extensions are matched literally: sizes are hex, so "mp4" + "0000…" must not read as "mp40".
    private val NAME_AND_SIZE = Regex(
        """^(.+?)\.(jpeg|jpg|png|mp4|avi|mov|opus|ogg|wav|pcm|txt|log|json|bin|dat)([0-9A-Fa-f]+)$""",
        RegexOption.IGNORE_CASE,
    )
    private val GENERIC_NAME_AND_SIZE = Regex("""^(.*[^0-9A-Fa-f])([0-9A-Fa-f]+)$""")
    private val RECORD_WIDTHS = listOf(40, 48, 32, 56, 64)

    data class Media(
        val file: File,
        val type: Int,
        val durationSec: Int,
        val thumbnail: File?,
        val capturedAtMs: Long,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "fileName" to file.name,
            "filePath" to file.absolutePath,
            "fileType" to type,
            "duration" to durationSec,
            "thumbnailPath" to (thumbnail?.absolutePath ?: ""),
            "timestamp" to capturedAtMs,
            "fileDate" to "",
            "sizeBytes" to file.length(),
        )
    }

    private data class Entry(val name: String, val ext: String, val size: Long)

    /** Unpacks/identifies one downloaded file. Returns null when it holds no usable media. */
    fun normalize(src: File, dir: File): Media? {
        if (!waitUntilStable(src, dir)) return null
        return try {
            val base = baseName(src)
            val out = extract(src, base, dir) ?: return null
            describe(out, dir)
        } catch (t: Throwable) {
            t.printStackTrace()
            null
        }
    }

    /** Fixes every bundle left in [dir] (e.g. from earlier imports) and returns all media found. */
    fun repairFolder(dir: File): List<Media> {
        val files = dir.listFiles() ?: return emptyList()
        val now = System.currentTimeMillis()
        val result = mutableListOf<Media>()
        for (f in files) {
            if (!f.isFile || f.name.startsWith(".") || f.name.startsWith("tmp_")) continue
            if (now - f.lastModified() < 60_000) continue // may still be downloading
            val ext = f.extension.lowercase(Locale.US)
            if (ext in IGNORED_EXT || f.name == "media.config") continue
            val needsWork = ext !in MEDIA_EXT || ext == "opus" || hasIndex(f)
            if (!needsWork) continue
            normalize(f, dir)?.let { result.add(it) }
        }
        return result
    }

    // ───────────────────────────── Extraction ─────────────────────────────

    private fun extract(src: File, base: String, dir: File): File? {
        val entries = readIndex(src)
        if (entries != null) {
            var offset = 0L
            for (entry in entries) {
                if (entry.ext.lowercase(Locale.US) in MEDIA_EXT) {
                    val ext = normalizeExt(entry.ext)
                    val size = minOf(entry.size, src.length() - offset)
                    if (size <= 0) return null
                    val out = File(dir, "$base.$ext")
                    val part = File(dir, ".${out.name}.part")
                    copyRange(src, offset, size, part)
                    if (sniffExt(part) == null) {
                        part.delete()
                        return null
                    }
                    if (out.exists()) out.delete()
                    if (!part.renameTo(out)) {
                        part.copyTo(out, overwrite = true)
                        part.delete()
                    }
                    if (src.absolutePath != out.absolutePath) src.delete()
                    return out
                }
                offset += entry.size
            }
            return null
        }

        // Voice notes: raw Opus packets the SDK never decodes (its recordingToPcm callback is
        // declared but never called). Decode them to a normal WAV file.
        if (sniffExt(src) == null) {
            val packetSize = detectOpusPacketSize(src)
            if (packetSize != null) {
                val wav = File(dir, "voice-${timestampDigits(base) ?: base}.wav")
                return if (opusPacketsToWav(src, packetSize, wav)) {
                    src.delete()
                    wav
                } else null
            }
        }

        // Plain file (no index): identify by content and give it the right extension.
        val ext = sniffExt(src) ?: return null
        if (src.extension.equals(ext, ignoreCase = true)) return src
        val out = uniqueTarget(dir, base, ext, src)
        if (out.exists()) { // same media already extracted earlier
            src.delete()
            return out
        }
        return if (src.renameTo(out)) out else null
    }

    private fun hasIndex(f: File): Boolean = try {
        RandomAccessFile(f, "r").use { raf ->
            if (raf.length() < 32) return false
            raf.seek(raf.length() - MAGIC.length)
            val buf = ByteArray(MAGIC.length)
            raf.readFully(buf)
            String(buf, Charsets.ISO_8859_1) == MAGIC
        }
    } catch (_: Throwable) { false }

    /** Reads the trailing index; null when the file isn't a bundle. */
    private fun readIndex(f: File): List<Entry>? {
        RandomAccessFile(f, "r").use { raf ->
            val len = raf.length()
            if (len < 32) return null
            val footer = ByteArray(16)
            raf.seek(len - 16)
            raf.readFully(footer)
            val footerText = String(footer, Charsets.ISO_8859_1)
            if (!footerText.endsWith(MAGIC)) return null
            val count = footerText.substring(0, 8).toIntOrNull(16) ?: return null
            if (count <= 0 || count > 32) return null

            for (width in RECORD_WIDTHS) {
                val tocLen = count.toLong() * width
                if (len < tocLen + 16) continue
                val toc = ByteArray(tocLen.toInt())
                raf.seek(len - 16 - tocLen)
                raf.readFully(toc)
                val entries = (0 until count).map { i ->
                    parseRecord(String(toc, i * width, width, Charsets.ISO_8859_1).trimEnd('\u0000', ' '))
                        ?: return@map null
                }
                if (entries.any { it == null }) continue
                val list = entries.filterNotNull()
                // The record width is right only if everything adds up to the file length.
                if (list.sumOf { it.size } + tocLen + 16 == len) return list
            }
            return null
        }
    }

    private fun parseRecord(record: String): Entry? {
        NAME_AND_SIZE.find(record)?.let { m ->
            return Entry(m.groupValues[1], m.groupValues[2], m.groupValues[3].toLongOrNull(16) ?: return null)
        }
        GENERIC_NAME_AND_SIZE.find(record)?.let { m ->
            val name = m.groupValues[1]
            val ext = name.substringAfterLast('.', "")
            return Entry(name.substringBeforeLast('.'), ext, m.groupValues[2].toLongOrNull(16) ?: return null)
        }
        return null
    }

    private fun copyRange(src: File, offset: Long, size: Long, tmp: File) {
        RandomAccessFile(src, "r").use { input ->
            FileOutputStream(tmp).use { output ->
                val inCh = input.channel
                val outCh = output.channel
                var done = 0L
                while (done < size) {
                    val n = inCh.transferTo(offset + done, size - done, outCh)
                    if (n <= 0) break
                    done += n
                }
                if (done != size) {
                    tmp.delete()
                    throw java.io.IOException("Short copy: $done of $size bytes")
                }
            }
        }
    }

    // ───────────────────────────── Identification ─────────────────────────────

    private fun sniffExt(f: File): String? {
        val head = ByteArray(12)
        val n = try { f.inputStream().use { it.read(head) } } catch (_: Throwable) { -1 }
        if (n < 12) return null
        return when {
            head[0] == 0xFF.toByte() && head[1] == 0xD8.toByte() && head[2] == 0xFF.toByte() -> "jpg"
            head[0] == 0x89.toByte() && head[1] == 'P'.code.toByte() && head[2] == 'N'.code.toByte() -> "png"
            String(head, 4, 4, Charsets.ISO_8859_1) == "ftyp" -> "mp4"
            String(head, 0, 4, Charsets.ISO_8859_1) == "RIFF" && String(head, 8, 4, Charsets.ISO_8859_1) == "AVI " -> "avi"
            String(head, 0, 4, Charsets.ISO_8859_1) == "RIFF" && String(head, 8, 4, Charsets.ISO_8859_1) == "WAVE" -> "wav"
            String(head, 0, 4, Charsets.ISO_8859_1) == "OggS" -> "ogg"
            else -> null
        }
    }

    private fun describe(file: File, dir: File): Media? {
        val ext = file.extension.lowercase(Locale.US)
        val capturedAt = timestampFromName(file.nameWithoutExtension) ?: file.lastModified()
        return when (ext) {
            "jpg", "jpeg", "png" -> {
                val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(file.absolutePath, opts)
                if (opts.outWidth > 0 && opts.outHeight > 0) {
                    Media(file, TYPE_IMAGE, 0, null, capturedAt)
                } else null
            }
            "mp4", "avi", "mov" -> describeVideo(file, dir, capturedAt)
            "ogg", "wav" -> {
                val seconds = durationSeconds(file) ?: return null
                Media(file, TYPE_AUDIO, seconds, null, capturedAt)
            }
            else -> null
        }
    }

    private fun describeVideo(file: File, dir: File, capturedAt: Long): Media? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            val ms = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            val hasVideo = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO) == "yes"
            if (!hasVideo && ms <= 0) return null
            val thumb = File(File(dir, THUMB_DIR).apply { mkdirs() }, "${file.nameWithoutExtension}.jpg")
            if (!thumb.exists()) {
                val frame = retriever.getFrameAtTime(500_000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    ?: retriever.frameAtTime
                if (frame != null) saveThumbnail(frame, thumb)
            }
            Media(file, TYPE_VIDEO, ((ms + 500) / 1000).toInt(), thumb.takeIf { it.exists() }, capturedAt)
        } catch (t: Throwable) {
            t.printStackTrace()
            null
        } finally {
            try { retriever.release() } catch (_: Throwable) {}
        }
    }

    private fun durationSeconds(file: File): Int? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            val ms = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
            ms?.let { ((it + 500) / 1000).toInt() }
        } catch (_: Throwable) {
            null
        } finally {
            try { retriever.release() } catch (_: Throwable) {}
        }
    }

    private fun saveThumbnail(frame: Bitmap, out: File) {
        val maxSide = 480f
        val scale = minOf(1f, maxSide / maxOf(frame.width, frame.height))
        val bmp = if (scale < 1f) {
            Bitmap.createScaledBitmap(frame, (frame.width * scale).toInt(), (frame.height * scale).toInt(), true)
        } else frame
        FileOutputStream(out).use { bmp.compress(Bitmap.CompressFormat.JPEG, 85, it) }
        if (bmp !== frame) bmp.recycle()
        frame.recycle()
    }

    // ───────────────────────────── Voice notes (raw Opus) ─────────────────────────────

    /**
     * The glasses store voice notes as back-to-back fixed-size Opus packets (40 bytes on current
     * firmware), each starting with the same Opus TOC byte. Returns the packet size, or null.
     */
    private fun detectOpusPacketSize(f: File): Int? {
        val len = f.length()
        if (len < 40) return null
        val data = f.readBytes()
        val toc = data[0].toInt() and 0xFF
        if (toc == 0) return null
        // Every packet must use the same Opus mode (TOC config, top 5 bits). The low bits
        // (stereo flag + frame packing) legitimately vary: the glasses mix padded "code 3"
        // packets (0x4B) with plain single-frame packets (0x48).
        val config = toc shr 3
        for (size in listOf(40, 20, 60, 80, 100, 120, 160)) {
            if (len % size != 0L) continue
            val packets = (len / size).toInt()
            var same = 0
            for (i in 0 until packets) if ((data[i * size].toInt() and 0xFF) shr 3 == config) same++
            if (same == packets) return size
        }
        return null
    }

    /** Duration in microseconds of one Opus packet, from its TOC byte (RFC 6716 §3.1). */
    private fun opusPacketDurationUs(packet: ByteArray): Long {
        val toc = packet[0].toInt() and 0xFF
        val config = toc shr 3
        val frameUs = when {
            config < 12 -> longArrayOf(10_000, 20_000, 40_000, 60_000)[config % 4]
            config < 16 -> longArrayOf(10_000, 20_000)[config % 2]
            else -> longArrayOf(2_500, 5_000, 10_000, 20_000)[config % 4]
        }
        val frames = when (toc and 0x03) {
            0 -> 1
            1, 2 -> 2
            else -> if (packet.size > 1) (packet[1].toInt() and 0x3F).coerceAtLeast(1) else 1
        }
        return frameUs * frames
    }

    private fun opusPacketsToWav(src: File, packetSize: Int, out: File): Boolean {
        val data = src.readBytes()
        val packets = data.size / packetSize
        if (packets == 0) return false

        // OpusHead identification header (mono, 16 kHz original rate, no pre-skip).
        val head = ByteBuffer.allocate(19).order(ByteOrder.LITTLE_ENDIAN).apply {
            put("OpusHead".toByteArray(Charsets.US_ASCII))
            put(1)                 // version
            put(1)                 // channels
            putShort(0)            // pre-skip
            putInt(16000)          // input sample rate
            putShort(0)            // output gain
            put(0)                 // channel mapping family
        }.array()
        fun longCsd(v: Long) = ByteBuffer.allocate(8).order(ByteOrder.nativeOrder()).putLong(v).array()

        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_OPUS, 48000, 1).apply {
            setByteBuffer("csd-0", ByteBuffer.wrap(head))
            setByteBuffer("csd-1", ByteBuffer.wrap(longCsd(0)))
            setByteBuffer("csd-2", ByteBuffer.wrap(longCsd(80_000_000)))
        }

        val codec = try {
            MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS)
        } catch (t: Throwable) {
            t.printStackTrace()
            return false
        }
        val pcmFile = File(out.parentFile, ".${out.name}.pcm")
        var sampleRate = 48000
        var channels = 1
        try {
            codec.configure(format, null, null, 0)
            codec.start()
            FileOutputStream(pcmFile).use { pcmOut ->
                val info = MediaCodec.BufferInfo()
                var next = 0
                var ptsUs = 0L
                var inputDone = false
                var outputDone = false
                var idleLoops = 0
                while (!outputDone && idleLoops < 2000) {
                    if (!inputDone) {
                        val inIndex = codec.dequeueInputBuffer(10_000)
                        if (inIndex >= 0) {
                            val buf = codec.getInputBuffer(inIndex)!!
                            buf.clear()
                            if (next < packets) {
                                val packet = data.copyOfRange(next * packetSize, (next + 1) * packetSize)
                                buf.put(packet)
                                codec.queueInputBuffer(inIndex, 0, packet.size, ptsUs, 0)
                                ptsUs += opusPacketDurationUs(packet)
                                next++
                            } else {
                                codec.queueInputBuffer(inIndex, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            }
                        }
                    }
                    val outIndex = codec.dequeueOutputBuffer(info, 10_000)
                    when {
                        outIndex >= 0 -> {
                            idleLoops = 0
                            if (info.size > 0) {
                                val outBuf = codec.getOutputBuffer(outIndex)!!
                                val chunk = ByteArray(info.size)
                                outBuf.position(info.offset)
                                outBuf.get(chunk)
                                pcmOut.write(chunk)
                            }
                            codec.releaseOutputBuffer(outIndex, false)
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                        }
                        outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val f = codec.outputFormat
                            sampleRate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                        }
                        else -> idleLoops++
                    }
                }
            }
            if (pcmFile.length() == 0L) return false
            writeWav(pcmFile, out, sampleRate, channels)
            return true
        } catch (t: Throwable) {
            t.printStackTrace()
            out.delete()
            return false
        } finally {
            try { codec.stop() } catch (_: Throwable) {}
            try { codec.release() } catch (_: Throwable) {}
            pcmFile.delete()
        }
    }

    private fun writeWav(pcm: File, out: File, sampleRate: Int, channels: Int) {
        val dataLen = pcm.length().toInt()
        val byteRate = sampleRate * channels * 2
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN).apply {
            put("RIFF".toByteArray()); putInt(36 + dataLen); put("WAVE".toByteArray())
            put("fmt ".toByteArray()); putInt(16); putShort(1); putShort(channels.toShort())
            putInt(sampleRate); putInt(byteRate); putShort((channels * 2).toShort()); putShort(16)
            put("data".toByteArray()); putInt(dataLen)
        }.array()
        FileOutputStream(out).use { o ->
            o.write(header)
            pcm.inputStream().use { it.copyTo(o) }
        }
    }

    // ───────────────────────────── Helpers ─────────────────────────────

    /** Waits until the SDK has finished writing (and possibly recompressing) the file. */
    private fun waitUntilStable(file: File, dir: File, maxWaitMs: Long = 12_000): Boolean {
        val start = System.currentTimeMillis()
        var lastLen = -1L
        var lastMod = -1L
        var hits = 0
        while (System.currentTimeMillis() - start < maxWaitMs) {
            if (file.exists()) {
                val len = file.length()
                val mod = file.lastModified()
                if (len > 0 && len == lastLen && mod == lastMod) {
                    hits++
                    val tmpBusy = dir.listFiles()?.any {
                        it.name.startsWith("tmp_") && System.currentTimeMillis() - it.lastModified() < 3000
                    } == true
                    if (hits >= 2 && !tmpBusy) return true
                } else {
                    hits = 0
                }
                lastLen = len
                lastMod = mod
            }
            try { Thread.sleep(350) } catch (_: InterruptedException) { return false }
        }
        return file.exists() && file.length() > 0
    }

    private fun baseName(f: File): String {
        val ext = f.extension.lowercase(Locale.US)
        return if (ext in MEDIA_EXT) f.nameWithoutExtension else f.name
    }

    private fun normalizeExt(ext: String): String = when (val e = ext.lowercase(Locale.US)) {
        "jpeg" -> "jpg"
        "opus" -> "ogg"
        else -> e
    }

    private fun uniqueTarget(dir: File, base: String, ext: String, src: File): File {
        val target = File(dir, "$base.$ext")
        return if (target.absolutePath == src.absolutePath) File(dir, "$base-1.$ext") else target
    }

    private fun timestampDigits(name: String): String? =
        Regex("""(\d{17})""").find(name)?.groupValues?.get(1)

    /** `photo-20261118050337005` → capture time from yyyyMMddHHmmssSSS. */
    private fun timestampFromName(name: String): Long? {
        val digits = Regex("""(\d{17})""").find(name)?.groupValues?.get(1) ?: return null
        return try {
            SimpleDateFormat("yyyyMMddHHmmssSSS", Locale.US).parse(digits)?.time
        } catch (_: Throwable) {
            null
        }
    }
}

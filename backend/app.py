from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS
import yt_dlp
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import os
import tempfile
import threading
import uuid
import json
import re

app = Flask(__name__)
CORS(app)

# ── Spotify Setup ──────────────────────────────────────────────
SPOTIFY_CLIENT_ID     = os.environ.get("SPOTIFY_CLIENT_ID", "edf56c389d164cf98d2a3c9e4c191291")
SPOTIFY_CLIENT_SECRET = os.environ.get("SPOTIFY_CLIENT_SECRET", "6b7f38143dc848168ca55de0f63b3a48")

sp = spotipy.Spotify(auth_manager=SpotifyClientCredentials(
    client_id=SPOTIFY_CLIENT_ID,
    client_secret=SPOTIFY_CLIENT_SECRET
))

# ── In-memory job tracker ──────────────────────────────────────
jobs = {}  # job_id -> { status, progress, filename, error }

# ── Helpers ────────────────────────────────────────────────────

def extract_spotify_id(url, type_):
    pattern = rf"spotify\.com/{type_}/([a-zA-Z0-9]+)"
    m = re.search(pattern, url)
    return m.group(1) if m else None


def get_spotify_metadata(url):
    """Return list of track dicts from a Spotify track/album/playlist URL."""
    tracks = []

    if "/track/" in url:
        tid = extract_spotify_id(url, "track")
        t   = sp.track(tid)
        tracks.append({
            "title":   t["name"],
            "artist":  ", ".join(a["name"] for a in t["artists"]),
            "album":   t["album"]["name"],
            "cover":   t["album"]["images"][0]["url"] if t["album"]["images"] else "",
            "duration": t["duration_ms"] // 1000,
        })

    elif "/album/" in url:
        aid    = extract_spotify_id(url, "album")
        album  = sp.album(aid)
        cover  = album["images"][0]["url"] if album["images"] else ""
        for item in album["tracks"]["items"]:
            tracks.append({
                "title":   item["name"],
                "artist":  ", ".join(a["name"] for a in item["artists"]),
                "album":   album["name"],
                "cover":   cover,
                "duration": item["duration_ms"] // 1000,
            })

    elif "/playlist/" in url:
        pid     = extract_spotify_id(url, "playlist")
        results = sp.playlist_tracks(pid)
        while results:
            for item in results["items"]:
                t = item["track"]
                if not t:
                    continue
                tracks.append({
                    "title":   t["name"],
                    "artist":  ", ".join(a["name"] for a in t["artists"]),
                    "album":   t["album"]["name"],
                    "cover":   t["album"]["images"][0]["url"] if t["album"]["images"] else "",
                    "duration": t["duration_ms"] // 1000,
                })
            results = sp.next(results) if results["next"] else None

    return tracks


def download_audio_track(track, quality, job_id, index=0, total=1):
    """Search YouTube Music and download as MP3 with embedded metadata."""
    query   = f"{track['title']} {track['artist']} audio"
    outdir  = tempfile.mkdtemp()
    outfile = os.path.join(outdir, f"{track['artist']} - {track['title']}.%(ext)s")

    bitrate_map = {"low": "128", "medium": "192", "high": "320"}
    bitrate     = bitrate_map.get(quality, "192")

    def progress_hook(d):
        if d["status"] == "downloading":
            pct = d.get("_percent_str", "?").strip()
            jobs[job_id]["progress"] = f"[{index+1}/{total}] {track['title']} — {pct}"
        elif d["status"] == "finished":
            jobs[job_id]["progress"] = f"[{index+1}/{total}] {track['title']} — converting..."

    ydl_opts = {
        "format":           "bestaudio/best",
        "outtmpl":          outfile,
        "quiet":            True,
        "no_warnings":      True,
        "progress_hooks":   [progress_hook],
        "postprocessors": [
            {
                "key":            "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": bitrate,
            },
            {"key": "FFmpegMetadata"},
            {"key": "EmbedThumbnail"},
        ],
        "add_metadata":     True,
        "writethumbnail":   True,
        "default_search":   "ytsearch",
        "metadata_from_title": "(?P<artist>.+?) - (?P<title>.+)",
        "postprocessor_args": [
            "-metadata", f"title={track['title']}",
            "-metadata", f"artist={track['artist']}",
            "-metadata", f"album={track['album']}",
        ],
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([f"ytsearch1:{query}"])

    # Find the produced mp3
    for f in os.listdir(outdir):
        if f.endswith(".mp3"):
            return os.path.join(outdir, f)
    return None


def download_video_job(url, fmt, quality, job_id):
    """Download a video/audio from any yt-dlp supported URL."""
    outdir  = tempfile.mkdtemp()
    outfile = os.path.join(outdir, "%(title)s.%(ext)s")

    def progress_hook(d):
        if d["status"] == "downloading":
            jobs[job_id]["progress"] = d.get("_percent_str", "?").strip()
        elif d["status"] == "finished":
            jobs[job_id]["progress"] = "Processing..."

    if fmt == "mp3":
        ydl_opts = {
            "format":         "bestaudio/best",
            "outtmpl":        outfile,
            "quiet":          True,
            "progress_hooks": [progress_hook],
            "postprocessors": [{
                "key":              "FFmpegExtractAudio",
                "preferredcodec":   "mp3",
                "preferredquality": "192",
            }],
        }
    else:
        quality_map = {"360p": "bestvideo[height<=360]+bestaudio", "720p": "bestvideo[height<=720]+bestaudio", "1080p": "bestvideo[height<=1080]+bestaudio"}
        ydl_opts = {
            "format":         quality_map.get(quality, "bestvideo+bestaudio"),
            "outtmpl":        outfile,
            "quiet":          True,
            "progress_hooks": [progress_hook],
            "merge_output_format": "mp4",
        }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            filename = ydl.prepare_filename(info)
            if fmt == "mp3":
                filename = os.path.splitext(filename)[0] + ".mp3"
        jobs[job_id]["status"]   = "done"
        jobs[job_id]["filename"] = filename
    except Exception as e:
        jobs[job_id]["status"] = "error"
        jobs[job_id]["error"]  = str(e)


# ── Routes ─────────────────────────────────────────────────────

@app.route("/api/spotify/metadata", methods=["POST"])
def spotify_metadata():
    data = request.json or {}
    url  = data.get("url", "")
    try:
        tracks = get_spotify_metadata(url)
        return jsonify({"tracks": tracks})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route("/api/spotify/download", methods=["POST"])
def spotify_download():
    data    = request.json or {}
    url     = data.get("url", "")
    quality = data.get("quality", "medium")

    job_id = str(uuid.uuid4())
    jobs[job_id] = {"status": "running", "progress": "Starting...", "filename": None, "error": None}

    def run():
        try:
            tracks = get_spotify_metadata(url)
            files  = []
            for i, track in enumerate(tracks):
                jobs[job_id]["progress"] = f"[{i+1}/{len(tracks)}] {track['title']}..."
                f = download_audio_track(track, quality, job_id, i, len(tracks))
                if f:
                    files.append(f)

            if len(files) == 1:
                jobs[job_id]["status"]   = "done"
                jobs[job_id]["filename"] = files[0]
            elif len(files) > 1:
                import zipfile
                zip_path = os.path.join(tempfile.mkdtemp(), "tracks.zip")
                with zipfile.ZipFile(zip_path, "w") as zf:
                    for f in files:
                        zf.write(f, os.path.basename(f))
                jobs[job_id]["status"]   = "done"
                jobs[job_id]["filename"] = zip_path
            else:
                jobs[job_id]["status"] = "error"
                jobs[job_id]["error"]  = "No tracks downloaded"
        except Exception as e:
            jobs[job_id]["status"] = "error"
            jobs[job_id]["error"]  = str(e)

    threading.Thread(target=run, daemon=True).start()
    return jsonify({"job_id": job_id})


@app.route("/api/video/download", methods=["POST"])
def video_download():
    data    = request.json or {}
    url     = data.get("url", "")
    fmt     = data.get("format", "mp4")
    quality = data.get("quality", "720p")

    job_id = str(uuid.uuid4())
    jobs[job_id] = {"status": "running", "progress": "Starting...", "filename": None, "error": None}
    threading.Thread(target=download_video_job, args=(url, fmt, quality, job_id), daemon=True).start()
    return jsonify({"job_id": job_id})


@app.route("/api/job/<job_id>", methods=["GET"])
def job_status(job_id):
    job = jobs.get(job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
    return jsonify({
        "status":   job["status"],
        "progress": job["progress"],
        "error":    job["error"],
    })


@app.route("/api/job/<job_id>/file", methods=["GET"])
def job_file(job_id):
    job = jobs.get(job_id)
    if not job or job["status"] != "done" or not job["filename"]:
        return jsonify({"error": "File not ready"}), 404
    path = job["filename"]
    name = os.path.basename(path)
    return send_file(path, as_attachment=True, download_name=name)


@app.route("/api/info", methods=["POST"])
def video_info():
    data = request.json or {}
    url  = data.get("url", "")
    try:
        with yt_dlp.YoutubeDL({"quiet": True}) as ydl:
            info = ydl.extract_info(url, download=False)
        return jsonify({
            "title":     info.get("title", ""),
            "uploader":  info.get("uploader", ""),
            "thumbnail": info.get("thumbnail", ""),
            "duration":  info.get("duration", 0),
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)

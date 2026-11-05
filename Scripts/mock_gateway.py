#!/usr/bin/env python3
"""Mock SSE di port 3001 untuk `events` dan kirim pesan. Mockoon tetap di port 3000 untuk service biasa."""
import json
import threading
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 3001
MOCKOON_URL = "http://127.0.0.1:3000"
KEEPALIVE_SECONDS = 15
REPLY_DELAY_SECONDS = 1
SEND_PATH = "/v1/chat/messages"
SKIPPED_HEADERS = {"connection", "content-length", "date", "host", "server", "transfer-encoding"}

frames = []  # (seq, teks frame), urut seq
changed = threading.Condition()
next_seq = 1000


def publish(event, build_data):
    """Menyimpan frame dengan seq baru supaya bisa di-replay lewat Last-Event-ID."""
    global next_seq
    with changed:
        next_seq += 1
        data = json.dumps(build_data(str(next_seq)), ensure_ascii=False)
        frames.append((next_seq, f"id: {next_seq}\nevent: {event}\ndata: {data}\n\n"))
        changed.notify_all()
        return next_seq


def publish_message(direction, payload, client_msg_id=None):
    return publish("message", lambda seq: {
        "message_id": str(uuid.uuid4()),
        "seq": seq,
        "direction": direction,
        "type": "text",
        "payload": payload,
        "status": "active",
        "client_msg_id": client_msg_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
    })


def publish_reply(question):
    publish_message("assistant", f"**Jawaban mock** untuk: {question}")
    publish("turn_end", lambda _: {"status": "completed", "active_turn_id": None})


class Gateway(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path.split("?")[0].endswith("/events"):
            self.stream_events()
        else:
            self.forward()

    def do_POST(self):
        if self.path.split("?")[0] == SEND_PATH:
            self.accept_message()
        else:
            self.forward()

    def read_body(self):
        return self.rfile.read(int(self.headers.get("Content-Length") or 0))

    def respond(self, status, body, headers=()):
        self.send_response(status)
        for name, value in headers:
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def accept_message(self):
        body = json.loads(self.read_body())
        question = body.get("payload", "")
        seq = publish_message("user", question, body.get("client_msg_id"))
        threading.Timer(REPLY_DELAY_SECONDS, publish_reply, args=[question]).start()
        ack = {"success": True, "data": {"message_id": str(uuid.uuid4()), "seq": str(seq)}}
        self.respond(202, json.dumps(ack).encode(), [("Content-Type", "application/json")])

    def stream_events(self):
        last_id = self.headers.get("Last-Event-ID")
        with changed:
            index = len(frames)
            if last_id and last_id.isdigit():
                index = next((i for i, frame in enumerate(frames) if frame[0] > int(last_id)), len(frames))
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        try:
            self.write_stream(": connected\n\n")
            while True:
                with changed:
                    has_frame = changed.wait_for(lambda: len(frames) > index, timeout=KEEPALIVE_SECONDS)
                    pending = frames[index:]
                index += len(pending)
                self.write_stream("".join(text for _, text in pending) if has_frame else ": keepalive\n\n")
        except OSError:
            pass  # Klien menutup stream.

    def write_stream(self, text):
        self.wfile.write(text.encode())
        self.wfile.flush()

    def forward(self):
        body = self.read_body()
        headers = {k: v for k, v in self.headers.items() if k.lower() not in SKIPPED_HEADERS}
        request = urllib.request.Request(
            MOCKOON_URL + self.path, data=body or None, headers=headers, method=self.command
        )
        try:
            with urllib.request.urlopen(request) as response:
                self.relay(response.status, response.read(), response.getheaders())
        except urllib.error.HTTPError as error:
            self.relay(error.code, error.read(), error.headers.items())

    def relay(self, status, body, headers):
        self.respond(status, body, [(k, v) for k, v in headers if k.lower() not in SKIPPED_HEADERS])


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Gateway).serve_forever()

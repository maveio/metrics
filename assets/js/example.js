import Hls from 'hls.js';

import { Metrics } from '@maveio/metrics';
Metrics.config = {
  socketPath: 'ws://localhost:3000/socket',
  apiKey: 'HDsj3NfKQTNwn5Ix9g+cfQ=='
}

const zep1 = new Metrics("#my_video", "MIB2", {
  video_id: 1234,
  component_type: "clip",
  foo: "test",
  space_id: "abcd"
}, {
  test: "big video"
})
zep1.monitor()

const video = document.getElementById('hls_video');
const videoSrc = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

if (Hls.isSupported()) {
  const hls = new Hls();
  hls.loadSource(videoSrc);
  hls.attachMedia(video);
  new Metrics(hls, "Big buck bunny").monitor()
} else if (video.canPlayType('application/vnd.apple.mpegurl')) {
  video.src = videoSrc;
  new Metrics("#hls_video", "Big buck bunny").monitor()
}

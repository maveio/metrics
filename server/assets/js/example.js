import Hls from 'hls.js';

import { Metrics } from '@maveio/metrics';
Metrics.config = {
  socketPath: 'ws://localhost:3001/socket',
  apiKey: 'HDsj3NfKQTNwn5Ix9g+cfQ=='
}

const zep1 = new Metrics("#my_video", "MIB2", {
  vid: "1234",
  t: "clip",
  sid: "abcd"
})

zep1.monitor()

const video = document.getElementById('hls_video');
const videoSrc = 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8';

if (Hls.isSupported()) {
  const hls = new Hls();
  hls.loadSource(videoSrc);
  hls.attachMedia(video);
  new Metrics(hls, "Apple", {
    vid: "5678",
    t: "player",
    sid: "apple"
  }).monitor()
} else if (video.canPlayType('application/vnd.apple.mpegurl')) {
  video.src = videoSrc;
  new Metrics("#hls_video", "Apple", {
    vid: "5678",
    t: "player",
    sid: "apple"
  }).monitor()
}

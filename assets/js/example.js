
// // TODO:
// // - make sure it already tracks video events without an active socket connection
// // - if connection breaks, collection all events and send them when reconnected
// // - respect DO NOT TRACK


// possibly add session metadata (user info is dangerous)

// video uniqueness per identifier + page url (+ metadata)

import { Metrics } from '@maveio/metrics';

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

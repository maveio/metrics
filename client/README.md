<div>
<br />
<p style="padding: 4px 0;">
  <a href="https://mave.io">
    <picture>
      <source srcset="https://mave.io/images/logo_white.svg" media="(prefers-color-scheme: dark)">
      <img src="https://mave.io/images/logo.svg"  alt="mave.io logo black" style="width: 183px;">
    </picture>
  </a>
</p>

# metrics

[![npm version](https://img.shields.io/npm/v/%40maveio%2Fmetrics?color=5850ec)](https://www.npmjs.com/package/@maveio/metrics)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/maveio/metrics/github-code-scanning%2Fcodeql?label=CodeQL&color=5850ec)](https://github.com/maveio/metrics/actions/workflows/github-code-scanning/codeql)
[![Discord server](https://img.shields.io/badge/Discord-mave.io-5850ec)](https://discord.gg/SBCKwnwHkC)

Our components library uses metrics to analyze video usage. This repo is meant to be transparent and accountable. This is only the client library and is part of [Mave Metrics Server](https://github.com/maveio/metrics-server)

[Install](#install) •
[Usage](#usage)

## Install

Install the package within your project

```
npm install @maveio/metrics
```

## Usage

```javascript
import { Metrics } from '@maveio/metrics';
Metrics.config = {
  socketPath: 'wss://{your domain here}/socket',
  apiKey: '{your api key here}',
};
```

To collect video events you will need to create an Metrics instance using each `HTMLVideoElement` or `Hls` object:

`new Metrics(<querySelector | Hls object>, <string>, <optional video query metadata>, <optional session query metadata>)`

For instance, you can do this in your page:

```javascript
const metrics = new Metrics('#my_video', 'label name', {
  my_custom_query_id: 1234,
});
metrics.monitor();
```

When you are using the hls.js library you can use the following code to monitor the video:

```javascript
const video = document.getElementById('hls_video');
const videoSrc = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

if (Hls.isSupported()) {
  const hls = new Hls();
  hls.loadSource(videoSrc);
  hls.attachMedia(video);
  new Metrics(hls, 'Big buck bunny').monitor();
} else if (video.canPlayType('application/vnd.apple.mpegurl')) {
  video.src = videoSrc;
  new Metrics('#hls_video', 'Big buck bunny').monitor();
}
```

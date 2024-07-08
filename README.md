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

# video metrics

[![Discord server](https://img.shields.io/badge/Discord-mave.io-5850ec)](https://discord.gg/SBCKwnwHkC)

We believe privacy advocates are doing a great job by creating better website analytics tools like [Plausible](https://plausible.io/) and [Simple Analytics](https://www.simpleanalytics.com/). However, video services like YouTube and Vimeo are becoming increasingly privacy invasive. They are essentially Google Analytics on steroids. We think that if you want to understand how your videos are performing on your site, you don't need to track your users. Instead, mave's metrics tracks usage, providing valuable insights without compromising user privacy.

This is a monorepo for both server and client library. The server is written in Elixir and the client is written in TypeScript.

### Server

![server](https://img.shields.io/github/v/tag/maveio/metrics?color=5850ec&label=version&filter=server*)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/maveio/metrics/sobelow.yml?label=Sobelow&color=5850ec)](https://github.com/maveio/metrics/actions/workflows/)

[Installation](#installation) •
[Configuration](#configuration) •
[API](#api)

### Client

![client](https://img.shields.io/github/v/tag/maveio/metrics?color=5850ec&label=version&filter=client*)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/maveio/metrics/github-code-scanning%2Fcodeql?label=CodeQL&color=5850ec)](https://github.com/maveio/metrics/actions/workflows/github-code-scanning/codeql)

[Install](#install) •
[Usage](#usage)

</div>

<p>
<img src="https://github.com/maveio/metrics/assets/238946/08d16cf5-32b1-47c6-9ec3-fbd094fb7df3"  alt="example" style="width: 50%;">

_This is not part of this repo, but an example what you can build with it (this is the data page on [mave.io](https://mave.io))_

</p>

# Server

This system runs on Elixir with Postgres and utilizes TimescaleDB. All video events are aggregated per session and sent over websockets. Each session is unique, as we don't track users. Therefore, when a user refreshes, it is considered a new view.

## Installation

Start with a git checkout of this project and run the following command:

```bash
docker compose up metrics
```

It will run on http://localhost:3000/ by default, with example videos and an example API key to get you started.

## Configuration

You can start the server without setting any environment variables. However, once you put it into production, we recommend setting the following environment variables (refer to `.envrc`):

```bash
METRICS_AUTH_ENABLED=true
METRICS_USER=mave
METRICS_PASSWORD=password
```

⚠️ Use the API to generate a new API key before going to production.

## API

### `/api/v1/plays` (POST or GET)

Retrieve the number of plays and associated data using the video's `identifier` and/or `query` for metadata.

The data is grouped into time buckets using the specified `interval`, such as `1 day`, within a given `timeframe`, for example, `1 month`. A play is defined based on a `minimum_watch_seconds` threshold, such as `3 seconds`.

An example response:

```json
{
  "views": [
    {
      "browser": {
        "brave": 0,
        "chrome": 1,
        "edge": 0,
        "firefox": 0,
        "ie": 0,
        "opera": 0,
        "other": 0,
        "safari": 0
      },
      "device": {
        "desktop": 1,
        "mobile": 0,
        "other": 0,
        "tablet": 0
      },
      "interval": "2023-05-02T00:00:00.000000",
      "platform": {
        "android": 0,
        "ios": 0,
        "linux": 0,
        "mac": 1,
        "other": 0,
        "windows": 0
      },
      "total_view_time": 6.267,
      "views": 1
    }
  ]
}
```

### `/api/v1/watching` (POST or GET)

Watching is a very simple request to determine how many people are currently watching a video. You can specify the video(s) by using the identifier or by querying for metadata.

The response will show you how many viewers are currently watching your request, here's an example response:

```json
{
  "watching": 231
}
```

### `/api/v1/sources` (POST or GET)

Retrieve the number of plays per source using the video's `identifier` and/or `query` for metadata. A source refers to the location where your video is placed, which can be particularly useful when embedding the same video across multiple pages/sites.

The data is grouped into time buckets with an `interval`, such as `1 day`, over a specified `timeframe`, for example, `1 month`. A play is defined by a `minimum_watch_seconds` threshold, such as `3 seconds`.

An example response:

```json
{
  "sources": [
    {
      "interval": "2023-04-02T08:29:00.000000",
      "path": "http://example.com/",
      "views": 1
    },
    {
      "interval": "2023-05-02T08:29:00.000000",
      "path": "http://example.com/",
      "views": 1
    },
    {
      "interval": "2023-05-02T08:41:00.000000",
      "path": "http://example.com/",
      "views": 1
    }
  ]
}
```

### `/api/v1/engagement` (POST or GET)

Engagement is used to determine which portion of a video has been watched, employing the same technique as the plays request. To retrieve engagement data, you can specify the video(s) by using the identifier or by querying for metadata. Set a timeframe to define the desired period, and indicate the number of ranges as an integer to segment the play duration of the sessions.

The response will show you which seconds of the video contains a view, here's an example response:

```json
{
  "engagement": [
    {
      "interval": "2024-03-01T00:00:00.000000Z",
      "per_second": [
        {
          "second": 0,
          "views": 5
        },
        {
          "second": 1,
          "views": 5
        },
        {
          "second": 2,
          "views": 3
        },
        {
          "second": 3,
          "views": 1
        },
        {
          "second": 4,
          "views": 1
        }
      ]
    }
  ]
}
```

### `/api/v1/keys` (POST)

Create a new API key to use with the client-side library.

An example response:

```json
{
  "key": "HDsj3NfKQTNwn5Ix9g+cfQ=="
}
```

### `/api/v1/keys` (GET)

Retrieves all API keys and whether they are disabled.

An example response:

```json
{
  "keys": [
    {
      "disabled_at": null,
      "key": "HDsj3NfKQTNwn5Ix9g+cfQ=="
    }
  ]
}
```

### `/api/v1/keys/{id}` (DELETE)

Revoke a key.

An example response:

```json
{
  "message": "Key revoked"
}
```

# Client

## Install

Install the package within your project

```
npm install @maveio/metrics
```

## Usage

```javascript
import { Metrics } from "@maveio/metrics";
Metrics.config = {
  socketPath: "wss://{your domain here}/socket",
  apiKey: "{your api key here}",
};
```

To collect video events you will need to create an Metrics instance using each `HTMLVideoElement` or `Hls` object:

`new Metrics(<querySelector | HTMLMediaElement | Hls object>, <video query metadata>)`

For instance, you can do this in your page:

```javascript
const metrics = new Metrics("#my_video", {
  vid: 1234,
});
metrics.monitor();
```

When you are using the hls.js library you can use the following code to monitor the video:

```javascript
const video = document.getElementById("hls_video");
const videoSrc = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";

const videoData = {
  vid: 1234, // add your own video id here, or any other metadata that you want to query
};

if (Hls.isSupported()) {
  const hls = new Hls();
  hls.loadSource(videoSrc);
  hls.attachMedia(video);
  new Metrics(hls, videoData).monitor();
} else if (video.canPlayType("application/vnd.apple.mpegurl")) {
  video.src = videoSrc;
  new Metrics("#hls_video", videoData).monitor();
}
```

Other options:

```javascript
const monitoringVideo = new Metrics("#hls_video", videoData).monitor();

// in some disconnect callback that removes the video from your view
monitoringVideo.demonitor();
```

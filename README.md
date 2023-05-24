<div align="center">
<br>
<p>
  <a href="https://mave.io">
    <img src="https://mave.io/images/logo.svg" alt="mave.io logo black" style="width: 230px;">
  </a>
</p>

# metrics server - track usage not users

We believe privacy advocates are doing a great job by creating better website analytical tools like [Plausible](https://plausible.io/) and [Simple Analytics](https://www.simpleanalytics.com/). However, video services like Youtube and Vimeo are becoming more privacy invasive. It's Google Analytics on steroid. We think if you want to know how your videos are performing on your site, you don't need to track your users - instead; mave metrics tracks usage.

[Getting started](#getting-started) •
[Installation](#installation) •
[Configuration](#configuration) •
[API](#API)

</div>

## Getting started

This runs on Elixir with Postgres with TimescaleDB, which can run on [fly.io](https://fly.io). All video events are aggregated per session and send over (Phoenix) websockets.

## Installation

`docker compose up metrics`

## Configuration

note: currently this is specifically made for mave.io - we'll need to make it more generic.

## API

See example requests: https://documenter.getpostman.com/view/7853984/2s93eU2uQy

### `/api/v1/plays`

Get the amount of plays and its data using the video `identifier` and/or `query` for metadata.

It is grouped by time buckets with `interval`, which can `1 day` over a `timeframe` of `1 month` for instance. The play is defined by using a `minimum_watch_seconds`, which can be `3 seconds` for instance.

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
            "device_type": {
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

### `/api/v1/engagement`

Engagement is meant to see which parts of a video have been watched using the same technique as the plays request. You can get a video(s) by `identifier` or `query` its metadata, set a `timeframe` for what period you want to get the engagement and set the amount of `ranges`, which is an integer to split up the play duration of sessions.

Example response:

```json
{
    "engagement": [
        {
            "range": 0,
            "range_time": {
                "from": 0.0,
                "to": 4.192
            },
            "viewers": 1
        },
        {
            "range": 1,
            "range_time": {
                "from": 4.192,
                "to": 8.384
            },
            "viewers": 1
        },
        {
            "range": 2,
            "range_time": {
                "from": 8.384,
                "to": 12.576
            },
            "viewers": 1
        }
    ]
}
```

### `/api/v1/sources`

Get the amount of plays per source using its `identifier` and/or `query` for metadata.

It is grouped by time buckets with `interval`, which can `1 day` over a `timeframe` of `1 month` for instance. The play is defined by using a `minimum_watch_seconds`, which can be `3 seconds` for instance.

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


## Todo

- [ ] (feature) views per source (url)

- [ ] (feature) dashboard
- [ ] (feature) calculate rebuffer time per video
- [ ] (feature) pagination
- [ ] (feature) get all individual events for a specific session

- [ ] (bug) missing unit tests
- [ ] (bug) iOS doesn't send fullscreen event


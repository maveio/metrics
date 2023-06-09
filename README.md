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

# metrics server

We believe privacy advocates are doing a great job by creating better website analytics tools like [Plausible](https://plausible.io/) and [Simple Analytics](https://www.simpleanalytics.com/). However, video services like YouTube and Vimeo are becoming increasingly privacy invasive. They are essentially Google Analytics on steroids. We think that if you want to understand how your videos are performing on your site, you don't need to track your users. Instead, mave metrics tracks usage, providing valuable insights without compromising user privacy.

[Getting started](#getting-started) •
[Installation](#installation) •
[Configuration](#configuration) •
[API](#api) •
[Client](https://github.com/maveio/metrics)

</div>

<p>
<img src="https://github.com/maveio/metrics/assets/238946/08d16cf5-32b1-47c6-9ec3-fbd094fb7df3"  alt="example" style="width: 50%;">

_This is not part of this repo, but an example what you can build with it (this is the data page on [mave.io](https://mave.io))_
</p>

## Getting started

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

There is a client-side library required to send the events to the server, which can be found here: https://github.com/maveio/metrics.

By default, the library will connect to `ws://localhost:3000/socket`. To modify this behavior, you'll need to import the library into your project and change its host by following these steps:

```javascript
import { Metrics } from '@maveio/metrics';
Metrics.socket_path = 'wss://{your domain here}/socket'
```

To collect video events, you will need to include the following script on your page:

```javascript
const metrics = new Metrics("#my_video", "label name", {
  custom_query_id: 1234,
})
metrics.monitor()
```

⚠️ Use the API to generate a new API key before going to production.

## API

See example requests on [Run with Postman](https://documenter.getpostman.com/view/7853984/2s93eU2uQy)

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

### `/api/v1/engagement` (POST or GET)

Engagement is used to determine the portions of a video that have been watched, employing the same technique as the plays request. To retrieve engagement data, you can specify the video(s) using the `identifier` or `query` for metadata, set a `timeframe` to define the desired period, and indicate the number of `ranges` as an integer to segment the play duration of sessions.

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

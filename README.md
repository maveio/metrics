<div align="center">
<br />
<br />
<p style="padding: 8px 0;">
  <a href="https://mave.io">
    <img src="https://mave.io/images/logo.svg" alt="mave.io logo black" style="width: 230px;">
  </a>
</p>
<br />

# mave metrics - track usage not users

We believe privacy advocates are doing a great job by creating better website analytical tools like [Plausible](https://plausible.io/) and [Simple Analytics](https://www.simpleanalytics.com/). However, video services like Youtube and Vimeo are becoming more privacy invasive. It's Google Analytics on steroid. We think if you want to know how your videos are performing on your site, you don't need to track your users - instead; mave metrics tracks usage.

[Getting started](#getting-started) •
[Installation](#installation) •
[Configuration](#configuration) •
[Integrations](#third-party-integrations)

</div>

## Getting started

This runs on Elixir with Postgres with TimescaleDB, which can run on [fly.io](https://fly.io). All video events are aggregated per session and send over (Phoenix) websockets.

## Installation

`docker compose up metrics`

## Configuration

note: currently this is specifically made for mave.io - we'll need to make it more generic.


## API

https://documenter.getpostman.com/view/7853984/2s93eU2uQy


## Todo

- [ ] (feature) views per source (url)

- [ ] (feature) dashboard
- [ ] (feature) calculate rebuffer time per video
- [ ] (feature) pagination
- [ ] (feature) get all individual events for a specific session

- [ ] (bug) missing unit tests
- [ ] (bug) iOS doesn't send fullscreen event


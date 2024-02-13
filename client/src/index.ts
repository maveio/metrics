import { Channel } from 'phoenix';
import Data from './data';
import Logger from './logger';

enum NativeEvents {
  DURATIONCHANGE = "durationchange",
  LOADEDMETADATA = "loadedmetadata",
  TIMEUPDATE = "timeupdate",
  LOADEDDATA = "loadeddata",
  CANPLAY = "canplay",
  CANPLAYTHROUGH = "canplaythrough",
  SEEKED = "seeked",
  RATECHANGE = "ratechange",
  VOLUMECHANGE = "volumechange",
  PLAYING = 'playing',
  ENDED = 'ended',
  PLAY = 'play',
  PAUSE = 'pause',
  ERROR = 'error',
}

interface Hls {
  media: HTMLMediaElement | null;
}

/**
 * The `Metrics` class is the core of Metrics used for monitoring video events.
 */
export class Metrics {
  VERSION = '__buildVersion';
  querySelectorable?: string;
  hls?: Hls;
  identifier?: string;
  metadata?: object;
  session_data?: object;

  timeout = 10000;

  #video!: HTMLVideoElement;
  #session!: Channel;

  #lastLastLastCurrentTime = 0;
  #lastLastCurrentTime = 0;
  #lastCurrentTime = 0;
  bufferInterval?: ReturnType<typeof setInterval>;
  bufferTimeInterval = 50;
  bufferOffset = (this.bufferTimeInterval - 40) / 1000;

  #playing = false;

  selectedLanguageVTT?: string;
  fullscreen = false;

  #resizeObserver?: ResizeObserver;
  #monitoring = false;

  /**
   * The `Metrics` class is the core of Metrics used for monitoring video events.
   * @param querySelectorable - A valid query selector to a HTMLVideoElement.
   * @param identifier - A unique identifier for the session (deprecated).
   * @param metadata - Video metadata to identify the video.
   * @param session - Additional metadata to be sent with the session (deprecated).
   */
  public constructor(
    querySelectorable: string,
    identifier: string,
    metadata?: object,
    session?: object
  );

  /**
   * The `Metrics` class is the core of Metrics used for monitoring video events.
   * @param videoElement - The actual HTMLMediaElement/HTMLVideoElement.
   * @param identifier - A unique identifier for the session (deprecated).
   * @param metadata - Video metadata to identify the video.
   * @param session - Additional metadata to be sent with the session (deprecated).
   */
  public constructor(
    videoElement: HTMLMediaElement | HTMLVideoElement,
    identifier: string,
    metadata?: object,
    session?: object
  );

  /**
   * Overload for hls.js
   * @param hls - A valid hls.js instance.
   * @param metadata - Video metadata to identify the video.
   * @param session - Additional metadata to be sent with the session (deprecated).
   */
  public constructor(
    hls: Hls,
    identifier: string,
    metadata?: object,
    session?: object
  );

  /**
     * The `Metrics` class is the core of Metrics used for monitoring video events.
     * @param querySelectorable - A valid query selector to a HTMLVideoElement.
     * @param metadata - Video metadata to identify the video.
     */
  public constructor(
    querySelectorable: string,
    metadata: object,
  );

  /**
   * The `Metrics` class is the core of Metrics used for monitoring video events.
   * @param videoElement - The actual HTMLMediaElement/HTMLVideoElement.
   * @param metadata - Video metadata to identify the video.
   */
  public constructor(
    videoElement: HTMLMediaElement | HTMLVideoElement,
    metadata: object
  );

  /**
   * Overload for hls.js
   * @param hls - A valid hls.js instance.
   * @param metadata - Video metadata to identify the video.
   */
  public constructor(
    hls: Hls,
    metadata: object,
  );

  public constructor(...args: Array<unknown>) {
    if (args.length <= 1) {
      Logger.error(
        'Metrics requires at least two arguments: a querySelectorable, hls instance or HTMLMediaElement/HTMLVideoElement and a metadata object to identify your video.'
      );
    } else {
      if (typeof args[0] === 'string') {
        this.querySelectorable = args[0];
        this.identifier = args[1] as string;
      }

      if (
        args[0] instanceof HTMLVideoElement ||
        args[0] instanceof HTMLMediaElement
      ) {
        this.#video = args[0] as HTMLVideoElement;
      } else if (typeof args[0] === 'object') {
        this.hls = args[0] as Hls;
      }

      if (args.length == 2 && typeof args[1] === 'object') {
        this.metadata = args[1] as object;
      } else {
        this.identifier = args[1] as string;
      }
      
      if (args[2]) {
        this.metadata = args[2] as object;
      }

      if (args[3]) {
        this.session_data = args[3] as object;
      }
    }
  }

  /**
   * Static method to set config.
   */
  public static set config(config: { apiKey: string; socketPath: string }) {
    Data.config = config;
  }

  /**
   * Starts actual monitoring.
   */
  monitor(): Metrics {
    const video = this.querySelectorable
      ? document.querySelector(this.querySelectorable)
      : this.hls?.media;

    if(this.#monitoring) return this;

    if (video || this.#video) {
      if (!this.#video) this.#video = video as HTMLVideoElement;
      this.#session = this.#initiateSession(this.#video);

      this.#recordSession();

      this.#monitoring = true;
    } else {
      Logger.error(
        `${this.querySelectorable} is not a valid reference to a HTMLVideoElement.`
      );
    }

    return this;
  }

  demonitor(): void {
    if(!this.#monitoring) return;
    
    this.#resizeObserver?.unobserve(this.#video);
    this.#unrecordSession();
    
    if (this.#session && this.#video) {
      Data.stopSession(this.#video);
    }
  }

  #initiateSession(video: HTMLVideoElement): Channel {
    Data.connect();
    return Data.startSession(video, {
      identifier: this.identifier,
      metadata: this.metadata,
      session_data: this.session_data,
    });
  }

  #recordSession() {
    for (const event of Object.values(NativeEvents)) {
      this.#video.addEventListener(event, this.#recordEvent.bind(this));
    }
  }

  #unrecordSession() {
    for (const event of Object.values(NativeEvents)) {
      this.#video.removeEventListener(event, this.#recordEvent.bind(this));
    }
  }

  #recordEvent(event: Event) {
    const params = {
      name: event.type,
      timestamp: new Date().getTime(),
    };

    switch (event.type) {
      case NativeEvents.PLAYING:
        this.#playing = true;
        this.#session?.push(
          'event',
          {
            ...params,
            name: 'play',
            from: this.#video?.currentTime,
          },
          this.timeout
        );

        break;
      case NativeEvents.PAUSE:
        this.#playing = false;
        
        this.#session?.push(
          'event',
          {
            ...params,
            to: this.#video?.currentTime,
          },
          this.timeout
        );

        break;
      case NativeEvents.SEEKED:
        // ignore time shift
        if(this.#playing && Math.abs(this.#lastLastLastCurrentTime - this.#lastLastCurrentTime) > 0.5) {
          this.#session?.push(
            'event',
            {
              ...params,
              name: 'pause',
              to: this.#lastLastLastCurrentTime,
            },
            this.timeout
          );
          this.#session?.push(
            'event',
            {
              ...params,
              name: 'play',
              to: this.#video?.currentTime,
            },
            this.timeout
          );
        }
        break;
      case NativeEvents.TIMEUPDATE:
        this.#lastLastLastCurrentTime = this.#lastLastCurrentTime;
        this.#lastLastCurrentTime = this.#lastCurrentTime;
        this.#lastCurrentTime = this.#video?.currentTime;
        break;
      
    }
  }
}

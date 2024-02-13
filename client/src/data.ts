import { Channel, Socket } from 'phoenix';
import { uuid } from './utils';

export interface ChannelTopic extends Channel {
  topic: string;
}

export default class Data {
  #socket!: Socket;
  #path: string;
  #key: string;
  #warningPathGiven = false;
  #warningKeyGiven = false;
  #channels = new Map<HTMLVideoElement, Channel>();
  private static instance: Data;

  private constructor() {
    return;
  }

  public static set config(config: { apiKey: string; socketPath: string }) {
    if (!Data.instance) {
      Data.instance = new Data();
    }
    Data.instance.#path = config.socketPath;
    Data.instance.#key = config.apiKey;
  }

  public static connect(): Socket {
    if (!Data.instance) {
      Data.instance = new Data();
    }

    if (!Data.instance.#key && !Data.instance.#warningKeyGiven) {
      console.warn(
        "[metrics]: Set apiKey using `Metrics.config = {apiKey: 'your_key'}`"
      );
      Data.instance.#warningKeyGiven = true;
    }

    if (!Data.instance.#path && !Data.instance.#warningPathGiven) {
      console.warn(
        "[metrics]: Set path using `Metrics.config = {socketPath: 'ws://localhost:3000/socket`}"
      );
      Data.instance.#warningPathGiven = true;
    }

    if (!Data.instance.#socket) {
      if (window) {

        const retryWindow = (tries: number) => {
          return [1000, 5000, 10000][tries - 1] || 25000
        }

        Data.instance.#socket = new Socket(
          Data.instance.#path || 'ws://localhost:3000/socket',
          {
            params: {
              source_url: window.location.href,
              key: Data.instance.#key,
            },
            reconnectAfterMs: retryWindow,
            rejoinAfterMs: retryWindow
          }
        );
        Data.instance.#socket.connect();
      }
    }

    return Data.instance.#socket;
  }

  public static startSession(
    video: HTMLVideoElement,
    metadata?: object
  ): Channel {
    const result = Data.instance.#channels.get(video);

    if (result) {
      return result;
    }

    const session = Data.instance.#socket.channel(`session:${uuid()}`, {
      ...metadata,
      source_url: window.location.href,
      key: Data.instance.#key,
    });

    Data.instance.#channels.set(video, session);

    session.join();

    return session;
  }

  public static stopSession(video: HTMLVideoElement): void {
    const session = Data.instance.#channels.get(video);

    if (session) {
      session.leave();
      Data.instance.#channels.delete(video);
    }
  }
}

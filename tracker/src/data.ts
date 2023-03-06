import { Channel, Socket } from "phoenix";
import { uuid } from "./utils";

export default class Data {
  #socket!: Socket;
  #channels = new Map<string, Channel>();
  private static instance: Data;


  private constructor() {
    return
  }

  public static connect(): Socket {
    if (!Data.instance) {
      Data.instance = new Data();

      if(window) {
        Data.instance.#socket = new Socket("__METRICS_ENDPOINT__", {
          params: {
            source_url: window.location.href
          }
        })

        Data.instance.#socket.connect();
      }
    }

    return Data.instance.#socket;
  }

  public static startSession(metadata?: object): Channel {
    const identifier = `session:${uuid()}`;
    const result = Data.instance.#channels.get(identifier);

    if (result) {
      return result;
    }

    const session = Data.instance.#socket.channel(identifier, metadata);

    Data.instance.#channels.set(identifier, session);

    session.join();

    return session;
  }
}

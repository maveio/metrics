export default class Logger {
  static log(message: string): void {
    console.log(`[mave_metrics]: ${message}`);
  }

  static error(message: string): void {
    console.error(`[mave_metrics]: ${message}`);
  }
}

export enum LogLevel {
  ERROR = 'error',
  WARN = 'warn',
  INFO = 'info',
  DEBUG = 'debug'
}

export class Logger {
  private static getTimestamp(): string {
    return new Date().toISOString();
  }

  private static formatMessage(level: LogLevel, message: string, meta?: any): string {
    const timestamp = Logger.getTimestamp();
    const metaString = meta ? ` ${JSON.stringify(meta)}` : '';
    return `[${timestamp}] ${level.toUpperCase()}: ${message}${metaString}`;
  }

  static error(message: string, meta?: any): void {
    console.error(Logger.formatMessage(LogLevel.ERROR, message, meta));
  }

  static warn(message: string, meta?: any): void {
    console.warn(Logger.formatMessage(LogLevel.WARN, message, meta));
  }

  static info(message: string, meta?: any): void {
    console.info(Logger.formatMessage(LogLevel.INFO, message, meta));
  }

  static debug(message: string, meta?: any): void {
    if (process.env.NODE_ENV === 'development') {
      console.debug(Logger.formatMessage(LogLevel.DEBUG, message, meta));
    }
  }

  static log(message: string, meta?: any): void {
    Logger.info(message, meta);
  }
} 
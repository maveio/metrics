import { replace } from 'esbuild-plugin-replace';
import { defineConfig } from 'tsup';

import * as dotenv from 'dotenv';
dotenv.config()

import json from './package.json';

export default defineConfig({
  platform: 'browser',
  entry: ['src/index.ts'],
  splitting: false,
  clean: true,
  dts: true,
  target: 'es2020',
  noExternal: ['phoenix'],
  esbuildPlugins: [
    replace({
      '__buildVersion': json.version,
      '__METRICS_ENDPOINT__': process.env.METRICS_ENDPOINT || 'wss://metrics.video-dns.com/socket',
    }),
  ]
})

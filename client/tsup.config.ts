import { replace } from 'esbuild-plugin-replace';
import { defineConfig } from 'tsup';

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
      __buildVersion: json.version,
    }),
  ],
});

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const buildId = process.env.GITHUB_SHA?.slice(0, 12) ?? String(Date.now());

export default defineConfig({
  plugins: [react()],
  define: {
    __CARTPORT_BUILD_ID__: JSON.stringify(buildId)
  },
  server: {
    allowedHosts: ['coco.local']
  }
});

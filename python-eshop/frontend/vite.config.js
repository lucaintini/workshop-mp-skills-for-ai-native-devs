import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const API_PORT = 8765;
const FRONTEND_PORT = 4321;
const SECURITY_HEADERS = {
  'Content-Security-Policy': "frame-ancestors 'none'",
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'no-referrer',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
};

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: './src/test/setup.js',
  },
  server: {
    host: '127.0.0.1',
    port: FRONTEND_PORT,
    strictPort: true,
    headers: SECURITY_HEADERS,
    proxy: {
      '/api': `http://127.0.0.1:${API_PORT}`,
      '/static': `http://127.0.0.1:${API_PORT}`,
    },
  },
  preview: {
    headers: SECURITY_HEADERS,
  },
});

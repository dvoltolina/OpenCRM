import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],

  build: {
    // Production build optimizations
    minify: 'esbuild',
    sourcemap: false, // No sourcemaps in production to protect code
    rollupOptions: {
      output: {
        manualChunks: {
          // Split vendor code for better caching
          vendor: ['react', 'react-dom', 'react-router-dom'],
          firebase: ['firebase/app', 'firebase/auth', 'firebase/firestore'],
        },
      },
    },
    // Security: Prevent leaking environment variables in bundle
    // Only VITE_ prefixed vars are included client-side
    chunkSizeWarningLimit: 600,
  },

  server: {
    // Development server config
    port: 5173,
    strictPort: false,
    // HTTPS for local dev (recommended for OAuth testing)
    // https: true, // Uncomment if needed
  },

  preview: {
    // Preview server (post-build) config
    port: 4173,
    strictPort: false,
  },

  // Define environment variable handling
  define: {
    // Ensure no dev-only variables leak to production
    __DEV__: JSON.stringify(process.env.NODE_ENV !== 'production'),
  },
})

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import './index.css';
import './styles/design-tokens.css';
import './components/ui/ui.css';
import 'leaflet/dist/leaflet.css';

// Initialize Firebase
import { initializeFirebase } from './lib/firebase';
import { registerServiceWorker } from './lib/registerServiceWorker';
initializeFirebase();
registerServiceWorker();

const queryClient = new QueryClient();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </BrowserRouter>
  </StrictMode>
);

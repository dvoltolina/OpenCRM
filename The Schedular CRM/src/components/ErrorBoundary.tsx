import { Component } from 'react';
import type { ErrorInfo, ReactNode } from 'react';
import { logEvent } from 'firebase/analytics';
import { getFirebaseAnalytics } from '../lib/firebase';
import { Button, Card, EmptyState, PageLayout } from './ui';
import './error-boundary.css';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  componentStack: string | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      componentStack: null,
    };
  }

  static getDerivedStateFromError(): State {
    return {
      hasError: true,
      error: null,
      componentStack: null,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.setState({
      error,
      componentStack: errorInfo.componentStack || null,
    });

    // HIPAA COMPLIANCE: Only log to console in dev to avoid browser-history PHI leakage
    if (import.meta.env.DEV) {
      console.error('Uncaught error:', error, errorInfo);
    }

    const analytics = getFirebaseAnalytics();
    if (analytics) {
      // HIPAA COMPLIANCE: Do NOT log error.message or stack traces to Analytics.
      // They may contain PHI (e.g., "Failed to load Patient John Doe").
      logEvent(analytics, 'app_crash', {
        error_name: error.name,
        timestamp: new Date().toISOString()
      });
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <PageLayout width="default" className="error-boundary">
          <Card className="error-boundary__card" padding="lg" tone="accent">
            <EmptyState
              eyebrow="Application Error"
              title="Something went wrong"
              description="We've logged the error and notified our team."
              actions={(
                <Button variant="primary" onClick={() => window.location.reload()}>
                  Reload Application
                </Button>
              )}
            />

            {import.meta.env.DEV && this.state.error ? (
              <section className="error-boundary__dev-panel" aria-label="Error details">
                <div className="error-boundary__dev-header">
                  <p className="error-boundary__dev-eyebrow">Development Diagnostics</p>
                  <p className="error-boundary__dev-title">
                    {this.state.error.name}: {this.state.error.message}
                  </p>
                </div>
                {this.state.componentStack ? (
                  <pre className="error-boundary__stack">
                    {this.state.componentStack.trim()}
                  </pre>
                ) : null}
              </section>
            ) : null}
          </Card>
        </PageLayout>
      );
    }

    return this.props.children;
  }
}

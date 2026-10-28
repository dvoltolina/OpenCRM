import { Component, type ErrorInfo, type ReactNode } from 'react';

type GlobalErrorBoundaryProps = {
  children: ReactNode;
};

type GlobalErrorBoundaryState = {
  hasError: boolean;
  message?: string;
};

export class GlobalErrorBoundary extends Component<
  GlobalErrorBoundaryProps,
  GlobalErrorBoundaryState
> {
  constructor(props: GlobalErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, message: undefined };
  }

  static getDerivedStateFromError(error: Error): GlobalErrorBoundaryState {
    return { hasError: true, message: error?.message ?? 'Unexpected error' };
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    console.error('[GlobalErrorBoundary] Unhandled error', error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: 24, maxWidth: 640, margin: '48px auto', textAlign: 'center' }}>
          <h2>Something went wrong</h2>
          <p className="muted">
            The app hit an unexpected error. Try reloading. If this persists, verify your environment
            variables and Firebase config.
          </p>
          {this.state.message ? <p className="error">{this.state.message}</p> : null}
          <button className="button button--primary" type="button" onClick={() => window.location.reload()}>
            Reload
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

import React, { type ReactNode } from 'react';

type AccessBoundaryProps = {
  children: ReactNode;
};

type AccessBoundaryState = {
  error: Error | null;
};

export class AccessBoundary extends React.Component<
  AccessBoundaryProps,
  AccessBoundaryState
> {
  constructor(props: AccessBoundaryProps) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error: Error): AccessBoundaryState {
    return { error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('Render error caught by AccessBoundary', error, info);
  }

  render() {
    const { error } = this.state;
    if (!error) {
      return this.props.children;
    }

    const message = error.message || 'Something went wrong.';
    const lower = message.toLowerCase();
    const isAccessError =
      lower.includes('insufficient role') ||
      lower.includes('business context') ||
      lower.includes('businessid') ||
      lower.includes('access denied');

    return (
      <div style={{ padding: 24 }}>
        <p className="eyebrow">Access</p>
        <h1>{isAccessError ? 'Access denied' : 'Something went wrong'}</h1>
        <p className="muted" style={{ marginTop: 8 }}>
          {message}
        </p>
        <div style={{ marginTop: 16 }}>
          <a className="button button--ghost" href="/dashboard">
            Go to dashboard
          </a>
        </div>
      </div>
    );
  }
}

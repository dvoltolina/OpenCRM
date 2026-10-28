import { useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import type { Location } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Button, Card, PageLayout } from '../components/ui';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { signIn, error, status } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as { from?: Location })?.from?.pathname || '/dashboard';

  useEffect(() => {
    if (status === 'authenticated') {
      navigate(from, { replace: true });
    }
    if (status === 'mfa_required') {
      navigate('/mfa', { state: { from }, replace: true });
    }
  }, [status, navigate, from]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      await signIn(email, password);
    } catch (err) {
      const code = (err as { code?: string })?.code;
      if (code === 'auth/multi-factor-auth-required') {
        navigate('/mfa', { state: { from }, replace: true });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <PageLayout width="wide">
      <div className="ui-auth">
        <Card className="ui-auth__panel" padding="lg">
          <header className="ui-auth__header">
            <p className="ui-auth__eyebrow">The Schedular CRM</p>
            <h1 className="ui-auth__title">Sign in to your workspace</h1>
            <p className="ui-auth__subtitle">
              Access pipeline, activity, reporting, and team operations from one secure workspace.
            </p>
          </header>
          <form onSubmit={handleSubmit} className="login-form">
            {status === 'mfa_required' && (
              <div className="info-banner">
                Multi-factor authentication is required for this business. Continue to complete verification.
              </div>
            )}
            {error && <div className="error-message">{error}</div>}

            <div className="form-group">
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                required
                disabled={isSubmitting}
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                disabled={isSubmitting}
              />
            </div>

            <Button type="submit" fullWidth disabled={isSubmitting}>
              {isSubmitting ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>
          <a className="ui-button ui-button--secondary ui-button--md ui-button--full-width" href="/demo">
            View demo workspace
          </a>
          <p className="ui-auth__footer">
            Owners and admins may be asked to complete multi-factor verification when workspace security policy requires it.
          </p>
        </Card>
      </div>
    </PageLayout>
  );
}

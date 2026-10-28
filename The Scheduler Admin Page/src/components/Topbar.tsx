import { useState } from 'react';

import { isDemoMode } from '../config/demo';
import { useDemoGuard } from '../hooks/useDemoGuard';

type TopbarProps = {
  onSignOut?: () => Promise<void> | void;
  userLabel?: string;
};

export function Topbar({ onSignOut, userLabel }: TopbarProps) {
  const [search, setSearch] = useState('');
  const { notifyBlocked } = useDemoGuard();

  // Parse user label to extract name and role
  const [userName, userRole] = userLabel?.split(' · ') || ['User', 'staff'];
  const userInitial = userName.charAt(0).toUpperCase();

  return (
    <header className="topbar">
      <input
        type="search"
        placeholder="Quick search (clients, staff, services)"
        className="topbar__search"
        value={search}
        onChange={(event) => setSearch(event.target.value)}
        aria-label="Quick search"
      />
      <div className="topbar__actions">
        <div className="topbar__user-chip" title={`${userName} (${userRole})`}>
          <div className="topbar__avatar" aria-hidden="true">
            {userInitial}
          </div>
          <div className="topbar__user-info">
            <span className="topbar__user-name">{userName}</span>
            <span className="topbar__user-role">{userRole}</span>
          </div>
        </div>
        <button
          type="button"
          className="button button--ghost topbar__notification-btn"
          aria-label="Notifications"
          title="Notifications"
        />
        <button
          type="button"
          className="button button--primary"
          aria-label="Create new item"
          onClick={() => notifyBlocked({ action: 'create item' })}
          disabled={isDemoMode}
          title={isDemoMode ? 'This action is disabled in demo mode.' : undefined}
        >
          <span aria-hidden="true">+</span> New
        </button>
        {onSignOut ? (
          <button
            type="button"
            className="button button--ghost"
            onClick={onSignOut}
            aria-label="Sign out"
          >
            Sign out
          </button>
        ) : null}
      </div>
    </header>
  );
}

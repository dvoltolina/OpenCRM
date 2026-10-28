import type { HTMLAttributes, ReactNode } from 'react';

export interface EmptyStateProps extends HTMLAttributes<HTMLDivElement> {
  eyebrow?: string;
  title: string;
  description?: ReactNode;
  actions?: ReactNode;
  tone?: 'default' | 'warning' | 'danger';
}

export function EmptyState({
  eyebrow,
  title,
  description,
  actions,
  tone = 'default',
  className = '',
  children,
  ...props
}: EmptyStateProps) {
  const classes = ['ui-empty-state', `ui-empty-state--${tone}`, className]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={classes} {...props}>
      {eyebrow ? <p className="ui-empty-state__eyebrow">{eyebrow}</p> : null}
      <h2 className="ui-empty-state__title">{title}</h2>
      {description ? <p className="ui-empty-state__description">{description}</p> : null}
      {children ? <div className="ui-empty-state__details">{children}</div> : null}
      {actions ? <div className="ui-empty-state__actions">{actions}</div> : null}
    </div>
  );
}

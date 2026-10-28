import type { HTMLAttributes } from 'react';

export interface PageLayoutProps extends HTMLAttributes<HTMLDivElement> {
  width?: 'default' | 'wide';
}

export function PageLayout({
  width = 'default',
  className = '',
  ...props
}: PageLayoutProps) {
  const classes = ['ui-page', `ui-page--${width}`, className].filter(Boolean).join(' ');
  return <div className={classes} {...props} />;
}

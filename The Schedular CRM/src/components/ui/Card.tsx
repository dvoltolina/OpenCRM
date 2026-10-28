import type { HTMLAttributes } from 'react';

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  padding?: 'sm' | 'md' | 'lg';
  tone?: 'default' | 'subtle' | 'accent';
}

export function Card({
  padding = 'md',
  tone = 'default',
  className = '',
  ...props
}: CardProps) {
  const classes = [
    'ui-card',
    `ui-card--padding-${padding}`,
    `ui-card--${tone}`,
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return <div className={classes} {...props} />;
}

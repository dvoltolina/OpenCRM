import type { HTMLAttributes, ReactNode } from 'react';

export interface ToolbarProps extends HTMLAttributes<HTMLDivElement> {
  start?: ReactNode;
  end?: ReactNode;
}

export function Toolbar({ start, end, className = '', ...props }: ToolbarProps) {
  const classes = ['ui-toolbar', className].filter(Boolean).join(' ');

  return (
    <div className={classes} {...props}>
      <div className="ui-toolbar__start">{start}</div>
      <div className="ui-toolbar__end">{end}</div>
    </div>
  );
}

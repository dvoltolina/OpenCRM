export const spacing = {
  xs: 8,
  sm: 12,
  md: 16,
  lg: 24,
  xl: 32,
} as const;

export const radii = {
  sm: 8,
  md: 12,
} as const;

export const shadows = {
  sm: '0 10px 28px rgba(15, 23, 42, 0.06)',
  md: '0 18px 40px rgba(15, 23, 42, 0.1)',
  lg: '0 28px 64px rgba(15, 23, 42, 0.16)',
} as const;

export const typography = {
  body: 14,
  bodyLg: 16,
  titleSm: 20,
  titleMd: 24,
  titleLg: 32,
} as const;

export const colors = {
  brand: '#2857e7',
  brandHover: '#1f46bf',
  canvas: '#edf2f8',
  surface: '#ffffff',
  surfaceSubtle: '#f6f9fc',
  border: '#d5deea',
  text: '#162033',
  textSecondary: '#51607a',
  textMuted: '#72819a',
  success: '#16794f',
  warning: '#946200',
  danger: '#b33a3a',
  info: '#1d5fd4',
} as const;

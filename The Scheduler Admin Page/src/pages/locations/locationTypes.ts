import type { UserRole } from '../../types/models';

export type StaffOption = {
  id: string;
  label: string;
  role: UserRole;
};

export type ServiceOption = {
  id: string;
  label: string;
  colorHex?: string;
};

export type DocEntry = {
  path: string;
  data: Record<string, unknown>;
  collection: string;
};

export type StaffSeed = {
  id: string;
  firstName: string;
  lastName: string;
  role: string;
  email: string;
  phone: string;
  colorHex: string;
  teamIds: string[];
  managedTeamIds?: string[];
  locationIds: string[];
};

export type LocationSeed = {
  id: string;
  name: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  timezone: string;
};

export type ServiceSeed = {
  id: string;
  name: string;
  durationMinutes: number;
  price: number;
  category: string;
  providerIds: string[];
  locationIds: string[];
  bufferMinutes: number;
};

export type StageSeed = {
  id: string;
  pipelineId: string;
  name: string;
  order: number;
  probability: number;
  colorHex: string;
};

const runtimeEnv =
  typeof process === 'undefined' || !process.env
    ? {}
    : process.env;

export const DEMO_PROJECT_ID =
  runtimeEnv.DEMO_FIREBASE_PROJECT_ID ||
  runtimeEnv.VITE_DEMO_FIREBASE_PROJECT_ID ||
  runtimeEnv.GCLOUD_PROJECT ||
  '';
export const BUSINESS_ID =
  runtimeEnv.DEMO_BUSINESS_ID ||
  runtimeEnv.VITE_DEMO_BUSINESS_ID ||
  'demo-business-001';
export const OWNER_UID = runtimeEnv.DEMO_OWNER_UID || 'demo-user-001';
export const OWNER_EMAIL = runtimeEnv.DEMO_OWNER_EMAIL || 'owner@demo.example.com';
export const OWNER_NAME = runtimeEnv.DEMO_OWNER_NAME || 'Avery Demo';
export const DEMO_DRY_RUN = runtimeEnv.DEMO_DRY_RUN === 'true';
export const NOW = new Date();

export const staffMembers: StaffSeed[] = [
  {
    id: 'demo-user-001',
    firstName: 'Avery',
    lastName: 'Demo',
    role: 'owner',
    email: 'owner@demo.example.com',
    phone: '555-0100',
    colorHex: '2563EB',
    teamIds: ['team-sales'],
    managedTeamIds: ['team-sales', 'team-success'],
    locationIds: ['location-demo-001', 'location-demo-002'],
  },
  {
    id: 'demo-user-002',
    firstName: 'Jordan',
    lastName: 'Sample',
    role: 'manager',
    email: 'manager@demo.example.com',
    phone: '555-0101',
    colorHex: '0F766E',
    teamIds: ['team-sales'],
    managedTeamIds: ['team-sales'],
    locationIds: ['location-demo-001'],
  },
  {
    id: 'demo-user-003',
    firstName: 'Quinn',
    lastName: 'Preview',
    role: 'staff',
    email: 'quinn@demo.example.com',
    phone: '555-0102',
    colorHex: '9333EA',
    teamIds: ['team-sales'],
    locationIds: ['location-demo-001', 'location-demo-003'],
  },
  {
    id: 'demo-user-004',
    firstName: 'Riley',
    lastName: 'Practice',
    role: 'staff',
    email: 'riley@demo.example.com',
    phone: '555-0103',
    colorHex: 'EA580C',
    teamIds: ['team-success'],
    locationIds: ['location-demo-002'],
  },
  {
    id: 'demo-user-005',
    firstName: 'Morgan',
    lastName: 'Sandbox',
    role: 'staff',
    email: 'morgan@demo.example.com',
    phone: '555-0104',
    colorHex: 'DC2626',
    teamIds: ['team-success'],
    locationIds: ['location-demo-002', 'location-demo-003'],
  },
  {
    id: 'demo-user-006',
    firstName: 'Parker',
    lastName: 'Mock',
    role: 'staff',
    email: 'parker@demo.example.com',
    phone: '555-0105',
    colorHex: '4F46E5',
    teamIds: ['team-partnerships'],
    locationIds: ['location-demo-003'],
  },
];

export const locations: LocationSeed[] = [
  {
    id: 'location-demo-001',
    name: 'North Demo Studio',
    address: '101 Demo Street',
    city: 'Sample City',
    state: 'CO',
    zipCode: '80001',
    timezone: 'America/Denver',
  },
  {
    id: 'location-demo-002',
    name: 'Riverfront Preview Center',
    address: '202 Preview Avenue',
    city: 'Mock Springs',
    state: 'CO',
    zipCode: '80002',
    timezone: 'America/Denver',
  },
  {
    id: 'location-demo-003',
    name: 'South Sandbox Annex',
    address: '303 Sandbox Boulevard',
    city: 'Example Hills',
    state: 'CO',
    zipCode: '80003',
    timezone: 'America/Denver',
  },
];

export const services: ServiceSeed[] = [
  { id: 'service-demo-001', name: 'Discovery Consultation', durationMinutes: 30, price: 65, category: 'Consultation', providerIds: ['demo-user-001', 'demo-user-002'], locationIds: ['location-demo-001'], bufferMinutes: 10 },
  { id: 'service-demo-002', name: 'Growth Planning Session', durationMinutes: 45, price: 95, category: 'Planning', providerIds: ['demo-user-001', 'demo-user-003'], locationIds: ['location-demo-001', 'location-demo-003'], bufferMinutes: 15 },
  { id: 'service-demo-003', name: 'Retention Review', durationMinutes: 60, price: 120, category: 'Customer Success', providerIds: ['demo-user-004', 'demo-user-005'], locationIds: ['location-demo-002'], bufferMinutes: 10 },
  { id: 'service-demo-004', name: 'Executive Demo Walkthrough', durationMinutes: 50, price: 150, category: 'Executive', providerIds: ['demo-user-001', 'demo-user-006'], locationIds: ['location-demo-001', 'location-demo-003'], bufferMinutes: 15 },
  { id: 'service-demo-005', name: 'Team Enablement Workshop', durationMinutes: 90, price: 220, category: 'Workshop', providerIds: ['demo-user-002', 'demo-user-004'], locationIds: ['location-demo-002'], bufferMinutes: 15 },
  { id: 'service-demo-006', name: 'Pipeline Health Check', durationMinutes: 40, price: 85, category: 'Sales Ops', providerIds: ['demo-user-002', 'demo-user-003'], locationIds: ['location-demo-001'], bufferMinutes: 10 },
  { id: 'service-demo-007', name: 'Expansion Strategy Review', durationMinutes: 60, price: 135, category: 'Partnerships', providerIds: ['demo-user-006'], locationIds: ['location-demo-003'], bufferMinutes: 10 },
  { id: 'service-demo-008', name: 'Operations Tune-Up', durationMinutes: 45, price: 100, category: 'Operations', providerIds: ['demo-user-005'], locationIds: ['location-demo-002', 'location-demo-003'], bufferMinutes: 10 },
  { id: 'service-demo-009', name: 'Quarterly Business Review', durationMinutes: 75, price: 180, category: 'Strategy', providerIds: ['demo-user-001', 'demo-user-004'], locationIds: ['location-demo-001', 'location-demo-002'], bufferMinutes: 15 },
  { id: 'service-demo-010', name: 'Client Reengagement Session', durationMinutes: 30, price: 70, category: 'Retention', providerIds: ['demo-user-003', 'demo-user-005'], locationIds: ['location-demo-002'], bufferMinutes: 10 },
];

export const clientNames = [
  ['Alex', 'Demo'], ['Bailey', 'Sample'], ['Casey', 'Preview'], ['Dakota', 'Mock'],
  ['Emery', 'Practice'], ['Finley', 'Sandbox'], ['Gray', 'Placeholder'], ['Harper', 'Trial'],
  ['Indigo', 'Example'], ['Jules', 'Fiction'], ['Kai', 'Template'], ['Lane', 'Specimen'],
  ['Marlow', 'Prototype'], ['Nico', 'Blueprint'], ['Oakley', 'Scenario'], ['Perry', 'Facsimile'],
  ['Quincy', 'Simulation'], ['Reese', 'StandIn'], ['Sage', 'Testwell'], ['Tatum', 'Showcase'],
  ['Urban', 'Demonstration'], ['Vale', 'Walkthrough'], ['Winter', 'Illustration'], ['Yael', 'Proof'],
];

export const companySeeds = [
  ['Acme Wellness Demo', 'Wellness', 'small'],
  ['Bluebird Sample Group', 'Professional Services', 'medium'],
  ['Cinder Preview Partners', 'Real Estate', 'medium'],
  ['Drift Mock Collective', 'Consulting', 'small'],
  ['Evergreen Practice Studio', 'Healthcare', 'large'],
  ['Foundry Sandbox Labs', 'Technology', 'medium'],
  ['Harbor Placeholder Co', 'Hospitality', 'small'],
  ['Juniper Trial Agency', 'Marketing', 'medium'],
  ['Kindred Example Works', 'Education', 'small'],
  ['Northstar Template Ventures', 'Finance', 'enterprise'],
];

export const pipelineIds = ['pipeline-demo-sales', 'pipeline-demo-partnerships'];

export const stages: StageSeed[] = [
  { id: 'stage-sales-01', pipelineId: pipelineIds[0], name: 'Lead', order: 1, probability: 10, colorHex: '#94A3B8' },
  { id: 'stage-sales-02', pipelineId: pipelineIds[0], name: 'Qualified', order: 2, probability: 30, colorHex: '#38BDF8' },
  { id: 'stage-sales-03', pipelineId: pipelineIds[0], name: 'Proposal', order: 3, probability: 55, colorHex: '#6366F1' },
  { id: 'stage-sales-04', pipelineId: pipelineIds[0], name: 'Negotiation', order: 4, probability: 75, colorHex: '#8B5CF6' },
  { id: 'stage-sales-05', pipelineId: pipelineIds[0], name: 'Won', order: 5, probability: 100, colorHex: '#10B981' },
  { id: 'stage-sales-06', pipelineId: pipelineIds[0], name: 'Lost', order: 6, probability: 0, colorHex: '#EF4444' },
  { id: 'stage-partner-01', pipelineId: pipelineIds[1], name: 'Intro', order: 1, probability: 20, colorHex: '#F59E0B' },
  { id: 'stage-partner-02', pipelineId: pipelineIds[1], name: 'Solution Fit', order: 2, probability: 45, colorHex: '#F97316' },
  { id: 'stage-partner-03', pipelineId: pipelineIds[1], name: 'Pilot', order: 3, probability: 70, colorHex: '#0EA5E9' },
  { id: 'stage-partner-04', pipelineId: pipelineIds[1], name: 'Signed', order: 4, probability: 100, colorHex: '#14B8A6' },
];

export const templateIds = [
  'message-template-demo-001',
  'message-template-demo-002',
  'message-template-demo-003',
  'message-template-demo-004',
];

export function dateOnly(value: Date): Date {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate());
}

export function shiftDate(days: number, hour: number, minute = 0): Date {
  const value = new Date(NOW.getTime());
  value.setDate(value.getDate() + days);
  value.setHours(hour, minute, 0, 0);
  return value;
}

export function phoneAt(offset: number): string {
  return '555-01' + String(offset).padStart(2, '0');
}

export function addDocument(
  docs: DocEntry[],
  collection: string,
  path: string,
  data: Record<string, unknown>,
): void {
  docs.push({ collection, path, data });
}

export function fullName(firstName: string, lastName: string): string {
  return firstName + ' ' + lastName;
}

export function shareable(
  staffIndex: number,
  visibility: 'team' | 'org' = 'team',
): Record<string, unknown> {
  const owner = staffMembers[staffIndex % staffMembers.length];
  return {
    ownerId: owner.id,
    ownerName: fullName(owner.firstName, owner.lastName),
    teamIds: owner.teamIds.slice(),
    visibility,
  };
}

export function reportIdAt(index: number): string {
  return 'report-definition-' + String(index + 1).padStart(2, '0');
}

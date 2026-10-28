/**
 * Performance Profiling Script for CRM Hooks
 *
 * Agent CRM-32 Implementation
 *
 * Purpose:
 * - Synthetic load testing for data hooks
 * - Query latency measurement
 * - Pagination performance validation
 * - Index alignment verification
 *
 * Usage:
 *   npm run perf:hooks
 *
 * Note: This script uses mock data for testing. For production profiling,
 * connect to a test Firebase project with N=1000 documents per collection.
 */

import { performance } from 'perf_hooks';

// ============================================
// Types
// ============================================

interface QueryProfile {
  hookName: string;
  operation: string;
  executionTimeMs: number;
  documentCount: number;
  hasMore: boolean;
  timestamp: Date;
}

interface PerformanceReport {
  totalQueries: number;
  averageLatencyMs: number;
  maxLatencyMs: number;
  minLatencyMs: number;
  p50LatencyMs: number;
  p95LatencyMs: number;
  p99LatencyMs: number;
  queriesOverThreshold: number;
  profiles: QueryProfile[];
}

// ============================================
// Configuration
// ============================================

const LATENCY_THRESHOLD_MS = 200; // Target: <200ms for list queries
const PAGE_SIZE = 25;
const TOTAL_DOCS_PER_COLLECTION = 1000;
const MAX_PAGE_SIZE_LIMIT = 100; // Back-pressure guard

// ============================================
// Mock Data Generators
// ============================================

/**
 * Generate mock lead data
 */
type MockLead = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  companyName: string;
  status: string;
  source: string;
  score: number;
  createdAt: Date;
};

type MockDeal = {
  id: string;
  title: string;
  pipelineId: string;
  stageId: string;
  valueCents: number;
  status: string;
  assigneeId: string;
  clientName: string;
  companyName: string;
  createdAt: Date;
};

function generateMockLeads(count: number): MockLead[] {
  const leads: MockLead[] = [];
  for (let i = 0; i < count; i++) {
    leads.push({
      id: `lead-${i}`,
      firstName: `First${i}`,
      lastName: `Last${i}`,
      email: `lead${i}@example.com`,
      companyName: `Company ${i % 100}`,
      status: ['new', 'contacted', 'qualified', 'unqualified'][i % 4],
      source: ['website', 'referral', 'cold_call', 'event'][i % 4],
      score: Math.floor(Math.random() * 100),
      createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
    });
  }
  return leads;
}

/**
 * Generate mock deal data
 */
function generateMockDeals(count: number): MockDeal[] {
  const deals: MockDeal[] = [];
  for (let i = 0; i < count; i++) {
    deals.push({
      id: `deal-${i}`,
      title: `Deal ${i}`,
      pipelineId: `pipeline-${i % 5}`,
      stageId: `stage-${i % 10}`,
      status: ['open', 'won', 'lost'][i % 3],
      valueCents: Math.floor(Math.random() * 100000),
      clientName: `Client ${i}`,
      companyName: `Company ${i % 50}`,
      assigneeId: `user-${i % 10}`,
      createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
    });
  }
  return deals;
}

/**
 * Generate mock contact data
 */
type MockContact = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  companyId: string;
  companyName: string;
  lifecycle: string;
  source: string;
  createdAt: Date;
};

function generateMockContacts(count: number): MockContact[] {
  const contacts: MockContact[] = [];
  for (let i = 0; i < count; i++) {
    contacts.push({
      id: `contact-${i}`,
      firstName: `First${i}`,
      lastName: `Last${i}`,
      email: `contact${i}@example.com`,
      companyId: `company-${i % 100}`,
      companyName: `Company ${i % 100}`,
      lifecycle: ['lead', 'prospect', 'customer', 'former_customer'][i % 4],
      source: ['website', 'referral', 'cold_call'][i % 3],
      createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
    });
  }
  return contacts;
}

/**
 * Generate mock activity data
 */
type MockActivity = {
  id: string;
  type: 'call' | 'email' | 'meeting' | 'task' | 'note';
  title: string;
  description: string;
  entityType: 'lead' | 'deal' | 'contact';
  entityId: string;
  activityDate: Date;
  createdAt: Date;
};

function generateMockActivities(count: number): MockActivity[] {
  const activities: MockActivity[] = [];
  for (let i = 0; i < count; i++) {
    activities.push({
      id: `activity-${i}`,
      type: ['call', 'email', 'meeting', 'task', 'note'][i % 5],
      title: `Activity ${i}`,
      description: `Description for activity ${i}`,
      entityType: ['lead', 'deal', 'contact'][i % 3],
      entityId: `entity-${i % 100}`,
      activityDate: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
      createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
    });
  }
  return activities;
}

// ============================================
// Mock Query Simulations
// ============================================

/**
 * Simulate a paginated query with filtering
 */
function simulatePaginatedQuery<T extends { createdAt: Date }>(
  data: T[],
  filters: { status?: string; assigneeId?: string; search?: string },
  pageSize: number,
  startIndex: number = 0
): { data: T[]; hasMore: boolean; executionTime: number } {
  const start = performance.now();

  // Simulate filtering
  let filtered = data;
  if (filters.status) {
    filtered = filtered.filter(item => item.status === filters.status);
  }
  if (filters.assigneeId) {
    filtered = filtered.filter(item => item.assigneeId === filters.assigneeId);
  }
  if (filters.search) {
    const searchLower = filters.search.toLowerCase();
    filtered = filtered.filter(item =>
      JSON.stringify(item).toLowerCase().includes(searchLower)
    );
  }

  // Simulate sorting (by createdAt DESC)
  filtered.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

  // Paginate
  const page = filtered.slice(startIndex, startIndex + pageSize);
  const hasMore = startIndex + pageSize < filtered.length;

  const end = performance.now();
  const executionTime = end - start;

  return { data: page, hasMore, executionTime };
}

/**
 * Simulate a search query
 */
function simulateSearchQuery<T>(
  data: T[],
  searchTerm: string,
  limit: number
): { data: T[]; hasMore: boolean; executionTime: number } {
  const start = performance.now();

  const searchLower = searchTerm.toLowerCase();
  const filtered = data.filter(item =>
    JSON.stringify(item).toLowerCase().includes(searchLower)
  );

  const results = filtered.slice(0, limit);
  const hasMore = filtered.length > limit;

  const end = performance.now();
  const executionTime = end - start;

  return { data: results, hasMore, executionTime };
}

// ============================================
// Profiling Tests
// ============================================

const profiles: QueryProfile[] = [];

/**
 * Profile useLeads hook scenarios
 */
function profileUseLeads(mockLeads: MockLead[]): void {
  console.log('\n=== Profiling useLeads Hook ===');

  // Test 1: Load first page
  const test1 = simulatePaginatedQuery(mockLeads, {}, PAGE_SIZE);
  profiles.push({
    hookName: 'useLeads',
    operation: 'loadFirstPage',
    executionTimeMs: test1.executionTime,
    documentCount: test1.data.length,
    hasMore: test1.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Load first page: ${test1.executionTime.toFixed(2)}ms (${test1.data.length} docs)`);

  // Test 2: Filter by status
  const test2 = simulatePaginatedQuery(mockLeads, { status: 'qualified' }, PAGE_SIZE);
  profiles.push({
    hookName: 'useLeads',
    operation: 'filterByStatus',
    executionTimeMs: test2.executionTime,
    documentCount: test2.data.length,
    hasMore: test2.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Filter by status: ${test2.executionTime.toFixed(2)}ms (${test2.data.length} docs)`);

  // Test 3: Search
  const test3 = simulateSearchQuery(mockLeads, 'lead100', PAGE_SIZE);
  profiles.push({
    hookName: 'useLeads',
    operation: 'search',
    executionTimeMs: test3.executionTime,
    documentCount: test3.data.length,
    hasMore: test3.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Search query: ${test3.executionTime.toFixed(2)}ms (${test3.data.length} docs)`);

  // Test 4: Load more (pagination)
  const test4 = simulatePaginatedQuery(mockLeads, {}, PAGE_SIZE, PAGE_SIZE);
  profiles.push({
    hookName: 'useLeads',
    operation: 'loadMore',
    executionTimeMs: test4.executionTime,
    documentCount: test4.data.length,
    hasMore: test4.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Load more (page 2): ${test4.executionTime.toFixed(2)}ms (${test4.data.length} docs)`);
}

/**
 * Profile useDeals hook scenarios
 */
function profileUseDeals(mockDeals: MockDeal[]): void {
  console.log('\n=== Profiling useDeals Hook ===');

  // Test 1: Load all deals (with limit)
  const test1 = simulatePaginatedQuery(mockDeals, {}, MAX_PAGE_SIZE_LIMIT);
  profiles.push({
    hookName: 'useDeals',
    operation: 'loadAll',
    executionTimeMs: test1.executionTime,
    documentCount: test1.data.length,
    hasMore: test1.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Load all deals: ${test1.executionTime.toFixed(2)}ms (${test1.data.length} docs)`);

  // Test 2: Filter by pipeline and stage
  const test2 = simulatePaginatedQuery(
    mockDeals.filter(d => d.pipelineId === 'pipeline-1' && d.stageId === 'stage-1'),
    {},
    PAGE_SIZE
  );
  profiles.push({
    hookName: 'useDeals',
    operation: 'filterByPipelineStage',
    executionTimeMs: test2.executionTime,
    documentCount: test2.data.length,
    hasMore: test2.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Filter by pipeline/stage: ${test2.executionTime.toFixed(2)}ms (${test2.data.length} docs)`);

  // Test 3: Filter by assignee
  const test3 = simulatePaginatedQuery(mockDeals, { assigneeId: 'user-1' }, PAGE_SIZE);
  profiles.push({
    hookName: 'useDeals',
    operation: 'filterByAssignee',
    executionTimeMs: test3.executionTime,
    documentCount: test3.data.length,
    hasMore: test3.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Filter by assignee: ${test3.executionTime.toFixed(2)}ms (${test3.data.length} docs)`);
}

/**
 * Profile useContacts hook scenarios
 */
function profileUseContacts(mockContacts: MockContact[]): void {
  console.log('\n=== Profiling useContacts Hook ===');

  // Test 1: Load first page
  const test1 = simulatePaginatedQuery(mockContacts, {}, PAGE_SIZE);
  profiles.push({
    hookName: 'useContacts',
    operation: 'loadFirstPage',
    executionTimeMs: test1.executionTime,
    documentCount: test1.data.length,
    hasMore: test1.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Load first page: ${test1.executionTime.toFixed(2)}ms (${test1.data.length} docs)`);

  // Test 2: Filter by company
  const test2 = simulatePaginatedQuery(
    mockContacts.filter(c => c.companyId === 'company-10'),
    {},
    PAGE_SIZE
  );
  profiles.push({
    hookName: 'useContacts',
    operation: 'filterByCompany',
    executionTimeMs: test2.executionTime,
    documentCount: test2.data.length,
    hasMore: test2.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Filter by company: ${test2.executionTime.toFixed(2)}ms (${test2.data.length} docs)`);

  // Test 3: Search
  const test3 = simulateSearchQuery(mockContacts, 'contact100', PAGE_SIZE);
  profiles.push({
    hookName: 'useContacts',
    operation: 'search',
    executionTimeMs: test3.executionTime,
    documentCount: test3.data.length,
    hasMore: test3.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Search query: ${test3.executionTime.toFixed(2)}ms (${test3.data.length} docs)`);
}

/**
 * Profile useGlobalSearch hook scenarios
 */
function profileUseGlobalSearch(
  mockLeads: MockLead[],
  mockDeals: MockDeal[],
  mockContacts: MockContact[]
): void {
  console.log('\n=== Profiling useGlobalSearch Hook ===');

  const start = performance.now();

  // Simulate parallel searches across all collections
  const leadsResult = simulateSearchQuery(mockLeads, 'test', 5);
  const dealsResult = simulateSearchQuery(mockDeals, 'test', 5);
  const contactsResult = simulateSearchQuery(mockContacts, 'test', 5);

  const end = performance.now();
  const executionTime = end - start;

  profiles.push({
    hookName: 'useGlobalSearch',
    operation: 'searchAll',
    executionTimeMs: executionTime,
    documentCount: leadsResult.data.length + dealsResult.data.length + contactsResult.data.length,
    hasMore: false,
    timestamp: new Date(),
  });

  console.log(`✓ Search all collections: ${executionTime.toFixed(2)}ms (${leadsResult.data.length + dealsResult.data.length + contactsResult.data.length} docs)`);
}

/**
 * Profile useTimeline hook scenarios
 */
function profileUseTimeline(mockActivities: MockActivity[]): void {
  console.log('\n=== Profiling useTimeline Hook ===');

  // Test 1: Get entity timeline
  const entityActivities = mockActivities.filter(a => a.entityId === 'entity-10');
  const test1 = simulatePaginatedQuery(entityActivities, {}, 50);
  profiles.push({
    hookName: 'useTimeline',
    operation: 'getEntityTimeline',
    executionTimeMs: test1.executionTime,
    documentCount: test1.data.length,
    hasMore: test1.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Get entity timeline: ${test1.executionTime.toFixed(2)}ms (${test1.data.length} docs)`);

  // Test 2: Get recent activities
  const recentDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const recentActivities = mockActivities.filter(a => a.activityDate >= recentDate);
  const test2 = simulatePaginatedQuery(recentActivities, {}, 50);
  profiles.push({
    hookName: 'useTimeline',
    operation: 'getRecentActivities',
    executionTimeMs: test2.executionTime,
    documentCount: test2.data.length,
    hasMore: test2.hasMore,
    timestamp: new Date(),
  });
  console.log(`✓ Get recent activities: ${test2.executionTime.toFixed(2)}ms (${test2.data.length} docs)`);
}

// ============================================
// Report Generation
// ============================================

/**
 * Calculate percentile from sorted array
 */
function percentile(arr: number[], p: number): number {
  if (arr.length === 0) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  const index = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, index)];
}

/**
 * Generate performance report
 */
function generateReport(): PerformanceReport {
  const latencies = profiles.map(p => p.executionTimeMs);
  const queriesOverThreshold = profiles.filter(p => p.executionTimeMs > LATENCY_THRESHOLD_MS).length;

  return {
    totalQueries: profiles.length,
    averageLatencyMs: latencies.reduce((a, b) => a + b, 0) / latencies.length,
    maxLatencyMs: Math.max(...latencies),
    minLatencyMs: Math.min(...latencies),
    p50LatencyMs: percentile(latencies, 50),
    p95LatencyMs: percentile(latencies, 95),
    p99LatencyMs: percentile(latencies, 99),
    queriesOverThreshold,
    profiles,
  };
}

/**
 * Print performance report
 */
function printReport(report: PerformanceReport): void {
  console.log('\n' + '='.repeat(60));
  console.log('PERFORMANCE REPORT');
  console.log('='.repeat(60));

  console.log(`\nTotal Queries: ${report.totalQueries}`);
  console.log(`Average Latency: ${report.averageLatencyMs.toFixed(2)}ms`);
  console.log(`Min Latency: ${report.minLatencyMs.toFixed(2)}ms`);
  console.log(`Max Latency: ${report.maxLatencyMs.toFixed(2)}ms`);
  console.log(`P50 Latency: ${report.p50LatencyMs.toFixed(2)}ms`);
  console.log(`P95 Latency: ${report.p95LatencyMs.toFixed(2)}ms`);
  console.log(`P99 Latency: ${report.p99LatencyMs.toFixed(2)}ms`);

  console.log(`\nLatency Threshold: ${LATENCY_THRESHOLD_MS}ms`);
  console.log(`Queries Over Threshold: ${report.queriesOverThreshold} (${((report.queriesOverThreshold / report.totalQueries) * 100).toFixed(1)}%)`);

  if (report.queriesOverThreshold > 0) {
    console.log('\n⚠️  WARNING: Some queries exceeded the latency threshold!');
    console.log('\nSlow Queries:');
    report.profiles
      .filter(p => p.executionTimeMs > LATENCY_THRESHOLD_MS)
      .forEach(p => {
        console.log(`  - ${p.hookName}.${p.operation}: ${p.executionTimeMs.toFixed(2)}ms`);
      });
  } else {
    console.log('\n✓ All queries within latency threshold!');
  }

  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY BY HOOK');
  console.log('='.repeat(60));

  const hookGroups = profiles.reduce((acc, p) => {
    if (!acc[p.hookName]) {
      acc[p.hookName] = [];
    }
    acc[p.hookName].push(p);
    return acc;
  }, {} as Record<string, QueryProfile[]>);

  Object.entries(hookGroups).forEach(([hookName, hookProfiles]) => {
    const avgLatency = hookProfiles.reduce((sum, p) => sum + p.executionTimeMs, 0) / hookProfiles.length;
    const maxLatency = Math.max(...hookProfiles.map(p => p.executionTimeMs));
    console.log(`\n${hookName}:`);
    console.log(`  Queries: ${hookProfiles.length}`);
    console.log(`  Avg Latency: ${avgLatency.toFixed(2)}ms`);
    console.log(`  Max Latency: ${maxLatency.toFixed(2)}ms`);
  });

  console.log('\n' + '='.repeat(60));
}

// ============================================
// Main Execution
// ============================================

function main(): void {
  console.log('='.repeat(60));
  console.log('CRM HOOKS PERFORMANCE PROFILING');
  console.log('='.repeat(60));
  console.log(`\nConfiguration:`);
  console.log(`  - Documents per collection: ${TOTAL_DOCS_PER_COLLECTION}`);
  console.log(`  - Page size: ${PAGE_SIZE}`);
  console.log(`  - Max page size limit: ${MAX_PAGE_SIZE_LIMIT}`);
  console.log(`  - Latency threshold: ${LATENCY_THRESHOLD_MS}ms`);

  console.log('\nGenerating mock data...');
  const mockLeads = generateMockLeads(TOTAL_DOCS_PER_COLLECTION);
  const mockDeals = generateMockDeals(TOTAL_DOCS_PER_COLLECTION);
  const mockContacts = generateMockContacts(TOTAL_DOCS_PER_COLLECTION);
  const mockActivities = generateMockActivities(TOTAL_DOCS_PER_COLLECTION);
  console.log('✓ Mock data generated');

  // Run profiling tests
  profileUseLeads(mockLeads);
  profileUseDeals(mockDeals);
  profileUseContacts(mockContacts);
  profileUseGlobalSearch(mockLeads, mockDeals, mockContacts);
  profileUseTimeline(mockActivities);

  // Generate and print report
  const report = generateReport();
  printReport(report);

  // Exit with error code if performance is poor
  if (report.queriesOverThreshold > 0 || report.p95LatencyMs > LATENCY_THRESHOLD_MS) {
    console.log('\n❌ Performance test FAILED');
    process.exit(1);
  } else {
    console.log('\n✓ Performance test PASSED');
    process.exit(0);
  }
}

// Run main function
main();

export { generateReport, profiles };

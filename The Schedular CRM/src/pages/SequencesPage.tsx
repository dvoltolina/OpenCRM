/**
 * SequencesPage Component
 * List and manage multi-step outreach sequences
 *
 * Phase 2 Implementation
 */

import { useState, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useSequences, useSequenceMutations } from '../hooks/useSequences';
import { SequenceList } from '../components/sequences/SequenceList';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import { getFeatureFlags } from '../config/features';
import type { SequenceStatus, SequenceFilters, Sequence } from '../types/sequences';
import './styles/sequences.css';

// ============================================
// Types
// ============================================

interface StatsCardProps {
  label: string;
  value: number | string;
  testId?: string;
}

// ============================================
// Sub-components
// ============================================

function StatsCard({ label, value, testId }: StatsCardProps) {
  return (
    <div className="sequences-page__stat-card" data-testid={testId}>
      <div className="sequences-page__stat-value">{value}</div>
      <div className="sequences-page__stat-label">{label}</div>
    </div>
  );
}

function UpgradePrompt() {
  return (
    <Card className="sequences-page__upgrade" padding="lg" data-testid="sequences-upgrade-prompt">
      <EmptyState
        eyebrow="Feature Locked"
        title="Sequences"
        description="Automate multi-step outreach with sequence cadences, follow-up reminders, and task workflows that run automatically."
        actions={<p className="sequences-page__upgrade-cta">Contact your administrator to enable this feature.</p>}
      />
    </Card>
  );
}

// ============================================
// Main Component
// ============================================

export function SequencesPage() {
  const navigate = useNavigate();
  const { crmUser } = useAuth();
  const features = getFeatureFlags();

  // Filter state
  const [statusFilter, setStatusFilter] = useState<SequenceStatus | ''>('');
  const [ownerFilter, setOwnerFilter] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  // Build filters object
  const filters: SequenceFilters = useMemo(() => ({
    status: statusFilter || undefined,
    ownerId: ownerFilter || undefined,
    search: searchQuery || undefined,
  }), [statusFilter, ownerFilter, searchQuery]);

  // Fetch sequences
  const { sequences, isLoading, error, refresh, getAccessSummary } = useSequences(filters);
  const {
    duplicateSequence,
    archiveSequence,
    activateSequence,
    pauseSequence,
    isMutating,
  } = useSequenceMutations();

  // Calculate stats
  const stats = useMemo(() => {
    const allSequences = sequences;
    const activeCount = allSequences.filter((s) => s.status === 'active').length;
    const totalEnrollments = allSequences.reduce((sum, s) => sum + s.stats.totalEnrolled, 0);
    const completedEnrollments = allSequences.reduce((sum, s) => sum + s.stats.completedCount, 0);
    const avgCompletionRate = totalEnrollments > 0
      ? Math.round((completedEnrollments / totalEnrollments) * 100)
      : 0;

    return {
      total: allSequences.length,
      active: activeCount,
      totalEnrollments,
      avgCompletionRate,
    };
  }, [sequences]);

  // Handlers
  const handleCreateSequence = useCallback(() => {
    navigate('/sequences/new');
  }, [navigate]);

  const handleEditSequence = useCallback((sequence: Sequence) => {
    navigate(`/sequences/${sequence.id}`);
  }, [navigate]);

  const handleDuplicateSequence = useCallback(async (sequence: Sequence) => {
    try {
      const duplicated = await duplicateSequence(sequence.id, `${sequence.name} (Copy)`);
      navigate(`/sequences/${duplicated.id}`);
    } catch {
      // Error handled by hook
    }
  }, [duplicateSequence, navigate]);

  const handleArchiveSequence = useCallback(async (sequence: Sequence) => {
    try {
      await archiveSequence(sequence.id);
      refresh();
    } catch {
      // Error handled by hook
    }
  }, [archiveSequence, refresh]);

  const handleToggleStatus = useCallback(async (sequence: Sequence) => {
    try {
      if (sequence.status === 'active') {
        await pauseSequence(sequence.id);
      } else if (sequence.status === 'paused' || sequence.status === 'draft') {
        await activateSequence(sequence.id);
      }
      refresh();
    } catch {
      // Error handled by hook
    }
  }, [activateSequence, pauseSequence, refresh]);

  const handleClearFilters = useCallback(() => {
    setStatusFilter('');
    setOwnerFilter('');
    setSearchQuery('');
  }, []);

  // Feature flag guard
  if (!features.enableSequences) {
    return (
      <PageLayout className="sequences-page" data-testid="sequences-page">
        <PageHeader
          eyebrow="Outreach"
          title="Sequences"
          subtitle="Automate multi-step outreach and task follow-up for CRM campaigns."
        />
        <UpgradePrompt />
      </PageLayout>
    );
  }

  const hasFilters = statusFilter || ownerFilter || searchQuery;

  return (
    <PageLayout className="sequences-page" data-testid="sequences-page">
      <PageHeader
        eyebrow="Outreach"
        title="Sequences"
        subtitle="Automate multi-step outreach campaigns, task reminders, and enrollment progress from one surface."
        actions={(
          <Button
            type="button"
            onClick={handleCreateSequence}
            data-testid="create-sequence-btn"
          >
            Create Sequence
          </Button>
        )}
      />

      <Card className="sequences-page__hero" padding="lg" tone="accent">
        <div className="sequences-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Sequence Health</p>
          <h2>{statusFilter ? `${statusFilter} sequences` : 'All sequences'}</h2>
          <p>
            Review active automations, enrollment volume, and completion performance without
            leaving the sequence workspace.
          </p>
        </div>
        <div className="sequences-page__hero-stats">
          <div>
            <span>Total sequences</span>
            <strong>{stats.total}</strong>
          </div>
          <div>
            <span>Active</span>
            <strong>{stats.active}</strong>
          </div>
          <div>
            <span>Avg completion</span>
            <strong>{stats.avgCompletionRate}%</strong>
          </div>
        </div>
      </Card>

      {/* Stats Cards */}
      <div className="sequences-page__stats">
        <StatsCard
          label="Total Sequences"
          value={stats.total}
          testId="stat-total"
        />
        <StatsCard
          label="Active"
          value={stats.active}
          testId="stat-active"
        />
        <StatsCard
          label="Total Enrollments"
          value={stats.totalEnrollments}
          testId="stat-enrollments"
        />
        <StatsCard
          label="Avg Completion"
          value={`${stats.avgCompletionRate}%`}
          testId="stat-completion"
        />
      </div>

      {/* Filters */}
      <Card className="sequences-page__filters-card" padding="md">
        <Toolbar
          start={(
            <div className="sequences-page__filters">
              <div className="sequences-page__filter-group">
                <label htmlFor="status-filter" className="sequences-page__filter-label">
                  Status
                </label>
                <select
                  id="status-filter"
                  className="sequences-page__filter-select"
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value as SequenceStatus | '')}
                  data-testid="status-filter"
                >
                  <option value="">All Statuses</option>
                  <option value="draft">Draft</option>
                  <option value="active">Active</option>
                  <option value="paused">Paused</option>
                  <option value="archived">Archived</option>
                </select>
              </div>

              <div className="sequences-page__filter-group">
                <label htmlFor="owner-filter" className="sequences-page__filter-label">
                  Owner
                </label>
                <select
                  id="owner-filter"
                  className="sequences-page__filter-select"
                  value={ownerFilter}
                  onChange={(e) => setOwnerFilter(e.target.value)}
                  data-testid="owner-filter"
                >
                  <option value="">All Owners</option>
                  <option value={crmUser?.id}>My Sequences</option>
                </select>
              </div>

              <div className="sequences-page__filter-group sequences-page__filter-group--search">
                <label htmlFor="search-filter" className="sequences-page__filter-label">
                  Search
                </label>
                <input
                  id="search-filter"
                  type="text"
                  className="sequences-page__filter-input"
                  placeholder="Search by name..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  data-testid="search-filter"
                />
              </div>

              {hasFilters && (
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  className="sequences-page__clear-filters"
                  onClick={handleClearFilters}
                >
                  Clear Filters
                </Button>
              )}
            </div>
          )}
          end={<span className="ui-results-count">{sequences.length} sequences</span>}
        />
      </Card>

      {/* Error State */}
      {error && (
        <div className="sequences-page__error" role="alert">
          <span>Failed to load sequences: {error.message}</span>
          <Button type="button" size="sm" onClick={refresh}>
            Retry
          </Button>
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <Card className="sequences-page__loading" padding="lg" data-testid="sequences-loading">
          <div className="sequences-page__spinner" />
          <span>Loading sequences...</span>
        </Card>
      )}

      {/* Sequence List */}
      {!isLoading && !error && (
        <Card className="sequences-page__list-card" padding="lg">
          <SequenceList
            sequences={sequences}
            onEdit={handleEditSequence}
            onDuplicate={handleDuplicateSequence}
            onArchive={handleArchiveSequence}
            onToggleStatus={handleToggleStatus}
            getAccessSummary={getAccessSummary}
            isLoading={isMutating}
          />
        </Card>
      )}

      {/* Empty State */}
      {!isLoading && !error && sequences.length === 0 && (
        <Card className="sequences-page__empty" padding="lg" data-testid="sequences-empty">
          <EmptyState
            eyebrow="Sequences"
            title={hasFilters ? 'No sequences match your filters' : 'No sequences yet'}
            description={
              hasFilters
                ? 'Try adjusting your filters or clearing them to see all sequences.'
                : 'Create your first sequence to automate multi-step outreach campaigns.'
            }
            actions={
              !hasFilters ? (
                <Button type="button" onClick={handleCreateSequence}>
                  Create Your First Sequence
                </Button>
              ) : undefined
            }
          />
        </Card>
      )}
    </PageLayout>
  );
}

export default SequencesPage;

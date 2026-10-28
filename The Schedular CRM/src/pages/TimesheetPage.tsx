/**
 * TimesheetPage
 * Manager view for reviewing and approving time entries from mobile punch clock
 *
 * Features:
 * - View pending time entries for approval
 * - Weekly timesheet view with overtime calculation
 * - Approve/reject entries with notes
 * - Export timesheet data for payroll
 */

import { useEffect, useState, useMemo, useCallback } from 'react';
import {
  useTimeEntries,
  useTimeEntryMutations,
  usePendingApprovals,
  formatMinutesAsTime,
  formatMinutesAsDecimal,
  calculateOvertimeMinutes,
  generatePayrollCSV,
  downloadCSV,
} from '../hooks';
import { useAuth } from '../context/AuthContext';
import { ConfirmDialog } from '../components/modals';
import { useModal } from '../hooks';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import type { TimeEntry, TimeEntryStatus } from '../types/models';
import './styles/timesheet-page.css';

// ============================================
// Helper Functions
// ============================================

function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  });
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
}

function formatDateRange(start: Date, end: Date): string {
  const startStr = start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  const endStr = end.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  return `${startStr} - ${endStr}`;
}

function getStatusBadgeClass(status: TimeEntryStatus): string {
  switch (status) {
    case 'active':
      return 'badge badge--info';
    case 'pending':
      return 'badge badge--warning';
    case 'approved':
      return 'badge badge--success';
    case 'rejected':
      return 'badge badge--danger';
    default:
      return 'badge';
  }
}

function getWeekStart(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  d.setDate(d.getDate() - day);
  d.setHours(0, 0, 0, 0);
  return d;
}

function getWeekEnd(date: Date): Date {
  const start = getWeekStart(date);
  const end = new Date(start);
  end.setDate(start.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return end;
}

// ============================================
// Component
// ============================================

export function TimesheetPage() {
  const { crmUser } = useAuth();
  const canApprove = crmUser?.role === 'owner' || crmUser?.role === 'admin';
  const canViewAll = ['owner', 'admin', 'manager'].includes(crmUser?.role || '');
  const [activeTab, setActiveTab] = useState<'pending' | 'all'>(() => (canApprove ? 'pending' : 'all'));
  const [selectedWeek, setSelectedWeek] = useState(() => new Date());
  const [rejectionReason, setRejectionReason] = useState('');

  const rejectModal = useModal<TimeEntry>();

  useEffect(() => {
    if (!canApprove && activeTab === 'pending') {
      setActiveTab('all');
    }
  }, [activeTab, canApprove]);

  // Week boundaries
  const weekStart = useMemo(() => getWeekStart(selectedWeek), [selectedWeek]);
  const weekEnd = useMemo(() => getWeekEnd(selectedWeek), [selectedWeek]);

  // Fetch pending approvals
  const {
    entries: pendingEntries,
    count: pendingCount,
    isLoading: pendingLoading,
    refresh: refreshPending,
  } = usePendingApprovals();

  // Fetch all entries for the week
  const {
    entries: weekEntries,
    isLoading: weekLoading,
    refresh: refreshWeek,
  } = useTimeEntries({
    dateFrom: weekStart,
    dateTo: weekEnd,
  });

  const { approve, reject, bulkApprove, isLoading: isMutating } = useTimeEntryMutations();

  // Calculate weekly totals
  const weeklyTotals = useMemo(() => {
    const approvedEntries = weekEntries.filter((e) => e.status === 'approved');
    const totalWorked = approvedEntries.reduce((sum, e) => sum + (e.workedMinutes || 0), 0);
    const totalBreaks = approvedEntries.reduce((sum, e) => sum + (e.breakMinutes || 0), 0);
    const { regularMinutes, overtimeMinutes } = calculateOvertimeMinutes(approvedEntries, 'weekly');

    return {
      totalWorked,
      totalBreaks,
      regularMinutes,
      overtimeMinutes,
      entryCount: approvedEntries.length,
    };
  }, [weekEntries]);

  // Group entries by day
  const entriesByDay = useMemo(() => {
    const grouped = new Map<string, TimeEntry[]>();

    weekEntries.forEach((entry) => {
      const dateKey = entry.clockInTime.toDateString();
      const existing = grouped.get(dateKey) || [];
      grouped.set(dateKey, [...existing, entry]);
    });

    return grouped;
  }, [weekEntries]);

  // Handlers
  const handleApprove = useCallback(
    async (entry: TimeEntry) => {
      try {
        await approve(entry.id);
        refreshPending();
        refreshWeek();
      } catch (err) {
        console.error('Failed to approve entry:', err);
      }
    },
    [approve, refreshPending, refreshWeek]
  );

  const handleReject = useCallback(async () => {
    if (!rejectModal.data || !rejectionReason.trim()) return;

    try {
      await reject(rejectModal.data.id, rejectionReason);
      rejectModal.close();
      setRejectionReason('');
      refreshPending();
      refreshWeek();
    } catch (err) {
      console.error('Failed to reject entry:', err);
    }
  }, [reject, rejectModal, rejectionReason, refreshPending, refreshWeek]);

  const handleBulkApprove = useCallback(async () => {
    const ids = pendingEntries.map((e) => e.id);
    if (ids.length === 0) return;

    try {
      const result = await bulkApprove(ids);
      refreshPending();
      refreshWeek();
      alert(`Approved ${result.approved} entries. ${result.failed} failed.`);
    } catch (err) {
      console.error('Failed to bulk approve:', err);
    }
  }, [pendingEntries, bulkApprove, refreshPending, refreshWeek]);

  const handlePrevWeek = useCallback(() => {
    setSelectedWeek((prev) => {
      const newDate = new Date(prev);
      newDate.setDate(newDate.getDate() - 7);
      return newDate;
    });
  }, []);

  const handleNextWeek = useCallback(() => {
    setSelectedWeek((prev) => {
      const newDate = new Date(prev);
      newDate.setDate(newDate.getDate() + 7);
      return newDate;
    });
  }, []);

  const handleThisWeek = useCallback(() => {
    setSelectedWeek(new Date());
  }, []);

  const handleExportPayroll = useCallback(() => {
    const approvedEntries = weekEntries.filter((e) => e.status === 'approved');
    if (approvedEntries.length === 0) {
      alert('No approved entries to export for this week.');
      return;
    }

    const csv = generatePayrollCSV(approvedEntries);
    const weekLabel = weekStart.toISOString().split('T')[0];
    downloadCSV(csv, `payroll-export-${weekLabel}.csv`);
  }, [weekEntries, weekStart]);

  const isLoading = pendingLoading || weekLoading;

  if (!canViewAll) {
    return (
      <PageLayout width="wide" className="timesheet-page">
        <PageHeader
          eyebrow="Operations"
          title="Timesheets"
          subtitle="Review mobile time entries, approvals, and payroll-ready weekly summaries."
        />
        <Card padding="lg">
          <EmptyState
            eyebrow="Restricted"
            title="You do not have permission to view timesheets"
            description="Manager, admin, or owner access is required for this workspace surface."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="timesheet-page">
      <PageHeader
        eyebrow="Operations"
        title="Timesheets"
        subtitle="Review pending approvals, audit weekly time entries, and export payroll-ready worked hours."
        actions={(
          <div className="timesheet-page__header-actions">
            {canApprove && pendingCount > 0 ? (
              <span className="badge badge--warning">{pendingCount} pending</span>
            ) : null}
          </div>
        )}
      />

      <Card className="timesheet-page__hero" padding="lg" tone="accent">
        <div className="timesheet-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current View</p>
          <h2>{activeTab === 'pending' ? 'Pending approvals' : 'Weekly timesheet'}</h2>
          <p>
            Review the current week, keep approvals moving, and export approved hours when the
            payroll set is ready.
          </p>
        </div>
        <div className="timesheet-page__hero-stats">
          <div>
            <span>Pending</span>
            <strong>{pendingCount}</strong>
          </div>
          <div>
            <span>Approved entries</span>
            <strong>{weeklyTotals.entryCount}</strong>
          </div>
          <div>
            <span>Worked</span>
            <strong>{formatMinutesAsDecimal(weeklyTotals.totalWorked)}h</strong>
          </div>
        </div>
      </Card>

      {/* Tabs */}
      <Card className="timesheet-page__tabs-card" padding="md">
        <Toolbar
          start={(
            <div className="tabs">
              {canApprove && (
                <button
                  type="button"
                  className={`tab ${activeTab === 'pending' ? 'tab--active' : ''}`}
                  onClick={() => setActiveTab('pending')}
                >
                  Pending Approval ({pendingCount})
                </button>
              )}
              <button
                type="button"
                className={`tab ${activeTab === 'all' ? 'tab--active' : ''}`}
                onClick={() => setActiveTab('all')}
              >
                Weekly View
              </button>
            </div>
          )}
          end={<span className="ui-results-count">{formatDateRange(weekStart, weekEnd)}</span>}
        />
      </Card>

      {/* Pending Approvals Tab */}
      {activeTab === 'pending' && canApprove && (
        <Card className="timesheet-section" padding="lg">
          {pendingEntries.length > 0 && (
            <div className="timesheet-actions">
              <Button
                onClick={handleBulkApprove}
                disabled={isMutating}
              >
                Approve All ({pendingCount})
              </Button>
            </div>
          )}

          {isLoading ? (
            <div className="loading-state">Loading...</div>
          ) : pendingEntries.length === 0 ? (
            <EmptyState
              eyebrow="Approvals"
              title="No pending time entries"
              description="There are no pending time entries waiting for approval right now."
            />
          ) : (
            <div className="timesheet-table-wrapper">
              <table className="timesheet-table">
                <thead>
                  <tr>
                    <th>Staff</th>
                    <th>Date</th>
                    <th>Clock In</th>
                    <th>Clock Out</th>
                    <th>Breaks</th>
                    <th>Worked</th>
                    <th>Location</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {pendingEntries.map((entry) => (
                    <tr key={entry.id} className={entry.clockInOutsideGeofence ? 'row--warning' : ''}>
                      <td>{entry.staffId}</td>
                      <td>{formatDate(entry.clockInTime)}</td>
                      <td>{formatTime(entry.clockInTime)}</td>
                      <td>{entry.clockOutTime ? formatTime(entry.clockOutTime) : '—'}</td>
                      <td>{entry.breakMinutes ? `${entry.breakMinutes}m` : '—'}</td>
                      <td>{entry.workedMinutes ? formatMinutesAsTime(entry.workedMinutes) : '—'}</td>
                      <td>
                        {entry.clockInOutsideGeofence && (
                          <span className="badge badge--warning" title="Outside geofence">Outside</span>
                        )}
                        {entry.clockInAddress ? (
                          <span className="location-text" title={entry.clockInAddress}>
                            {entry.clockInAddress.slice(0, 30)}...
                          </span>
                        ) : (
                          '—'
                        )}
                      </td>
                      <td>
                        <div className="action-buttons">
                          <Button
                            size="sm"
                            onClick={() => handleApprove(entry)}
                            disabled={isMutating}
                          >
                            Approve
                          </Button>
                          <Button
                            variant="danger"
                            size="sm"
                            onClick={() => rejectModal.open(entry)}
                            disabled={isMutating}
                          >
                            Reject
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {/* Weekly View Tab */}
      {activeTab === 'all' && (
        <Card className="timesheet-section" padding="lg">
          {/* Week Navigation */}
          <div className="week-navigation">
            <Button variant="secondary" onClick={handlePrevWeek}>
              Prev
            </Button>
            <span className="week-label">{formatDateRange(weekStart, weekEnd)}</span>
            <Button variant="secondary" onClick={handleNextWeek}>
              Next
            </Button>
            <Button variant="secondary" size="sm" onClick={handleThisWeek}>
              This Week
            </Button>
            <Button
              size="sm"
              onClick={handleExportPayroll}
              disabled={weeklyTotals.entryCount === 0}
              title="Export approved entries for payroll"
            >
              Export CSV
            </Button>
          </div>

          {/* Weekly Summary */}
          <div className="weekly-summary">
            <div className="summary-card">
              <span className="summary-label">Total Worked</span>
              <span className="summary-value">{formatMinutesAsTime(weeklyTotals.totalWorked)}</span>
              <span className="summary-decimal">({formatMinutesAsDecimal(weeklyTotals.totalWorked)} hrs)</span>
            </div>
            <div className="summary-card">
              <span className="summary-label">Regular</span>
              <span className="summary-value">{formatMinutesAsTime(weeklyTotals.regularMinutes)}</span>
            </div>
            <div className="summary-card summary-card--overtime">
              <span className="summary-label">Overtime (1.5x)</span>
              <span className="summary-value">{formatMinutesAsTime(weeklyTotals.overtimeMinutes)}</span>
            </div>
            <div className="summary-card">
              <span className="summary-label">Breaks</span>
              <span className="summary-value">{formatMinutesAsTime(weeklyTotals.totalBreaks)}</span>
            </div>
          </div>

          {/* Entries by Day */}
          {isLoading ? (
            <div className="loading-state">Loading...</div>
          ) : weekEntries.length === 0 ? (
            <EmptyState
              eyebrow="Weekly View"
              title="No time entries for this week"
              description="Move to another week or wait for staff time entries to sync into this view."
            />
          ) : (
            <div className="daily-entries">
              {Array.from(entriesByDay.entries()).map(([dateKey, entries]) => (
                <div key={dateKey} className="day-section">
                  <h3 className="day-header">
                    {formatDate(new Date(dateKey))}
                    <span className="day-total">
                      {formatMinutesAsTime(
                        entries.reduce((sum, e) => sum + (e.workedMinutes || 0), 0)
                      )}
                    </span>
                  </h3>
                  <table className="timesheet-table">
                    <thead>
                      <tr>
                        <th>Staff</th>
                        <th>In</th>
                        <th>Out</th>
                        <th>Breaks</th>
                        <th>Worked</th>
                        <th>Status</th>
                        <th>Notes</th>
                      </tr>
                    </thead>
                    <tbody>
                      {entries.map((entry) => (
                        <tr key={entry.id}>
                          <td>{entry.staffId}</td>
                          <td>{formatTime(entry.clockInTime)}</td>
                          <td>{entry.clockOutTime ? formatTime(entry.clockOutTime) : '—'}</td>
                          <td>{entry.breakMinutes ? `${entry.breakMinutes}m` : '—'}</td>
                          <td>{entry.workedMinutes ? formatMinutesAsTime(entry.workedMinutes) : '—'}</td>
                          <td>
                            <span className={getStatusBadgeClass(entry.status)}>
                              {entry.status}
                            </span>
                          </td>
                          <td>
                            {entry.staffNotes && (
                              <span className="timesheet-page__note-pill" title={entry.staffNotes}>Staff note</span>
                            )}
                            {entry.managerNotes && (
                              <span className="timesheet-page__note-pill" title={entry.managerNotes}>Manager note</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {/* Reject Modal */}
      <ConfirmDialog
        isOpen={rejectModal.isOpen}
        onCancel={() => {
          rejectModal.close();
          setRejectionReason('');
        }}
        onConfirm={handleReject}
        title="Reject Time Entry"
        message={
          <div>
            <p>Reject this time entry? Please provide a reason:</p>
            <textarea
              className="rejection-input"
              placeholder="Reason for rejection..."
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              rows={3}
            />
          </div>
        }
        confirmText="Reject"
        variant="danger"
      />
    </PageLayout>
  );
}

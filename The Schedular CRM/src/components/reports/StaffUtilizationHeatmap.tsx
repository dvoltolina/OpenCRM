/**
 * StaffUtilizationHeatmap Component
 * Heatmap showing staff utilization by hour and day of week
 *
 * Agent CRM-31 Implementation
 */

import { useState } from 'react';
import type { StaffUtilizationData } from '../../hooks/useAdvancedAnalytics';
import './reports.css';

// ============================================
// Types
// ============================================

export interface StaffUtilizationHeatmapProps {
  /** Utilization data by staff */
  data: StaffUtilizationData[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Selected staff ID */
  selectedStaffId?: string;
  /** Staff selection callback */
  onStaffChange?: (staffId: string) => void;
}

// ============================================
// Constants
// ============================================

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const HOURS = Array.from({ length: 16 }, (_, i) => {
  const hour = i + 6; // 6am - 10pm
  return hour > 12 ? `${hour - 12}pm` : `${hour}am`;
});

// ============================================
// Helper Functions
// ============================================

/**
 * Get color intensity based on appointment count
 */
function getHeatmapColor(count: number, max: number): string {
  if (count === 0) return 'var(--color-bg-secondary)';

  const intensity = Math.min(count / max, 1);

  if (intensity < 0.2) return 'var(--color-heatmap-1)';
  if (intensity < 0.4) return 'var(--color-heatmap-2)';
  if (intensity < 0.6) return 'var(--color-heatmap-3)';
  if (intensity < 0.8) return 'var(--color-heatmap-4)';
  return 'var(--color-heatmap-5)';
}

// ============================================
// Component
// ============================================

/**
 * StaffUtilizationHeatmap - Shows staff appointment density by hour and day
 *
 * @example
 * ```tsx
 * const utilizationData = analytics.getStaffUtilization(dateRange, selectedStaffId);
 *
 * <StaffUtilizationHeatmap
 *   data={utilizationData}
 *   selectedStaffId={selectedStaffId}
 *   onStaffChange={setSelectedStaffId}
 * />
 * ```
 */
export function StaffUtilizationHeatmap({
  data,
  isLoading = false,
  selectedStaffId,
  onStaffChange,
}: StaffUtilizationHeatmapProps) {
  const [hoveredCell, setHoveredCell] = useState<{ day: number; hour: number } | null>(null);

  // Get selected staff data
  const staffData = selectedStaffId
    ? data.find(d => d.staffId === selectedStaffId)
    : data[0]; // Default to first staff

  if (isLoading) {
    return (
      <div className="staff-utilization">
        <div className="staff-utilization__loading">
          <div className="staff-utilization__spinner" />
          <p>Loading utilization data...</p>
        </div>
      </div>
    );
  }

  if (!staffData || data.length === 0) {
    return (
      <div className="staff-utilization">
        <div className="staff-utilization__empty">
          <p>No utilization data available for this period</p>
        </div>
      </div>
    );
  }

  // Find max count for color scaling
  const maxCount = Math.max(
    ...staffData.heatmap.flat(),
    1 // Minimum 1 to avoid division by zero
  );

  const getDayName = (day: number): string => DAYS[day];
  const getHourLabel = (hour: number): string => HOURS[hour];

  return (
    <div className="staff-utilization">
      <div className="staff-utilization__header">
        <h2 className="staff-utilization__title">Staff Utilization Heatmap</h2>
        {data.length > 1 && (
          <div className="staff-utilization__selector">
            <label>Staff Member:</label>
            <select
              value={staffData.staffId}
              onChange={(e) => onStaffChange?.(e.target.value)}
              className="staff-utilization__select"
            >
              {data.map((staff) => (
                <option key={staff.staffId} value={staff.staffId}>
                  {staff.staffName}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      <div className="staff-utilization__stats">
        <div className="staff-utilization__stat">
          <span className="staff-utilization__stat-label">Total Appointments</span>
          <span className="staff-utilization__stat-value">{staffData.totalAppointments}</span>
        </div>
        <div className="staff-utilization__stat">
          <span className="staff-utilization__stat-label">Avg Per Day</span>
          <span className="staff-utilization__stat-value">
            {staffData.averagePerDay.toFixed(1)}
          </span>
        </div>
        <div className="staff-utilization__stat">
          <span className="staff-utilization__stat-label">Peak Time</span>
          <span className="staff-utilization__stat-value">
            {getDayName(staffData.peakDay)} {getHourLabel(staffData.peakHour - 6)}
          </span>
        </div>
      </div>

      <div className="staff-utilization__heatmap-container">
        <div className="staff-utilization__heatmap">
          {/* Hour labels */}
          <div className="staff-utilization__hour-labels">
            <div className="staff-utilization__corner-cell"></div>
            {HOURS.map((hour, index) => (
              <div key={index} className="staff-utilization__hour-label">
                {hour}
              </div>
            ))}
          </div>

          {/* Heatmap grid */}
          {DAYS.map((day, dayIndex) => (
            <div key={dayIndex} className="staff-utilization__row">
              <div className="staff-utilization__day-label">{day}</div>
              {staffData.heatmap[dayIndex].map((count, hourIndex) => (
                <div
                  key={hourIndex}
                  className="staff-utilization__cell"
                  style={{
                    backgroundColor: getHeatmapColor(count, maxCount),
                  }}
                  onMouseEnter={() => setHoveredCell({ day: dayIndex, hour: hourIndex })}
                  onMouseLeave={() => setHoveredCell(null)}
                  title={`${day} ${HOURS[hourIndex]}: ${count} appointment${count !== 1 ? 's' : ''}`}
                >
                  {count > 0 && <span className="staff-utilization__count">{count}</span>}
                </div>
              ))}
            </div>
          ))}
        </div>

        {/* Tooltip */}
        {hoveredCell && (
          <div className="staff-utilization__tooltip">
            <strong>{getDayName(hoveredCell.day)} {getHourLabel(hoveredCell.hour)}</strong>
            <p>
              {staffData.heatmap[hoveredCell.day][hoveredCell.hour]} appointment
              {staffData.heatmap[hoveredCell.day][hoveredCell.hour] !== 1 ? 's' : ''}
            </p>
          </div>
        )}
      </div>

      <div className="staff-utilization__legend">
        <span className="staff-utilization__legend-label">Appointment Density:</span>
        <div className="staff-utilization__legend-scale">
          <div className="staff-utilization__legend-item">
            <div
              className="staff-utilization__legend-color"
              style={{ backgroundColor: 'var(--color-bg-secondary)' }}
            />
            <span>0</span>
          </div>
          <div className="staff-utilization__legend-item">
            <div
              className="staff-utilization__legend-color"
              style={{ backgroundColor: 'var(--color-heatmap-1)' }}
            />
            <span>Low</span>
          </div>
          <div className="staff-utilization__legend-item">
            <div
              className="staff-utilization__legend-color"
              style={{ backgroundColor: 'var(--color-heatmap-3)' }}
            />
            <span>Med</span>
          </div>
          <div className="staff-utilization__legend-item">
            <div
              className="staff-utilization__legend-color"
              style={{ backgroundColor: 'var(--color-heatmap-5)' }}
            />
            <span>High</span>
          </div>
        </div>
      </div>

      <div className="staff-utilization__info">
        <p>
          <strong>Note:</strong> Heatmap shows appointment density by hour (6am-10pm) and day of
          week. Darker colors indicate higher appointment volume.
        </p>
      </div>
    </div>
  );
}

export default StaffUtilizationHeatmap;

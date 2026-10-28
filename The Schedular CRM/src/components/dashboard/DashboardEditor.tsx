/**
 * DashboardEditor Component
 * Drag-and-drop widget layout editor for customizing dashboards.
 *
 * HIPAA Compliance:
 * - Dashboard configurations contain no PHI
 * - Widget positioning is UI metadata only
 * - All dashboard changes are logged via audit service
 *
 * Agent CRM - Task 7 Implementation
 */

import { useState, useCallback, useMemo, useRef, useEffect } from 'react';
import type { Dashboard, DashboardWidget, WidgetType } from '../../types/reporting';

// ============================================
// Types
// ============================================

export interface DashboardEditorProps {
  /** Dashboard being edited */
  dashboard: Dashboard;
  /** Available widgets to add */
  availableWidgets: AvailableWidget[];
  /** Callback when layout changes */
  onLayoutChange: (widgets: DashboardWidget[]) => void;
  /** Callback when widget is added */
  onWidgetAdd: (widget: Omit<DashboardWidget, 'id'>) => void;
  /** Callback when widget is removed */
  onWidgetRemove: (widgetId: string) => void;
  /** Callback when widget is configured */
  onWidgetConfigure: (widgetId: string, config: Partial<DashboardWidget>) => void;
  /** Callback when editing is done */
  onSave: () => Promise<void>;
  /** Callback when editing is cancelled */
  onCancel: () => void;
  /** Whether save is in progress */
  isSaving?: boolean;
}

export interface AvailableWidget {
  type: WidgetType;
  label: string;
  icon: string;
  description: string;
  defaultWidth: number;
  defaultHeight: number;
}

interface DragState {
  isDragging: boolean;
  widgetId: string | null;
  startX: number;
  startY: number;
  offsetX: number;
  offsetY: number;
}

interface ResizeState {
  isResizing: boolean;
  widgetId: string | null;
  direction: 'e' | 's' | 'se' | null;
  startX: number;
  startY: number;
  startWidth: number;
  startHeight: number;
}

// ============================================
// Constants
// ============================================

const GRID_COLUMNS = 12;
const GRID_ROW_HEIGHT = 80;
const WIDGET_MARGIN = 16;

const DEFAULT_AVAILABLE_WIDGETS: AvailableWidget[] = [
  {
    type: 'metric',
    label: 'Metric',
    icon: '🔢',
    description: 'Display a single key metric',
    defaultWidth: 3,
    defaultHeight: 2,
  },
  {
    type: 'report',
    label: 'Chart',
    icon: '📊',
    description: 'Display a report chart',
    defaultWidth: 6,
    defaultHeight: 4,
  },
  {
    type: 'leaderboard',
    label: 'Leaderboard',
    icon: '🏆',
    description: 'Show top performers',
    defaultWidth: 4,
    defaultHeight: 4,
  },
  {
    type: 'activity_feed',
    label: 'Activity Feed',
    icon: '📋',
    description: 'Recent activity stream',
    defaultWidth: 4,
    defaultHeight: 4,
  },
  {
    type: 'tasks',
    label: 'Tasks',
    icon: '✅',
    description: 'Upcoming and overdue tasks',
    defaultWidth: 4,
    defaultHeight: 4,
  },
];

// ============================================
// Helper Functions
// ============================================

function getWidgetPosition(
  widget: DashboardWidget,
  containerWidth: number
): { left: number; top: number; width: number; height: number } {
  const columnWidth = containerWidth / GRID_COLUMNS;
  const x = widget.x ?? 0;
  const y = widget.y ?? 0;
  const width = widget.width ?? 4;
  const height = widget.height ?? 2;

  return {
    left: x * columnWidth + WIDGET_MARGIN / 2,
    top: y * GRID_ROW_HEIGHT + WIDGET_MARGIN / 2,
    width: width * columnWidth - WIDGET_MARGIN,
    height: height * GRID_ROW_HEIGHT - WIDGET_MARGIN,
  };
}

function findNextAvailablePosition(
  widgets: DashboardWidget[],
  newWidth: number,
  newHeight: number
): { x: number; y: number } {
  // Find the lowest available position
  const occupiedCells = new Set<string>();

  for (const widget of widgets) {
    const x = widget.x ?? 0;
    const y = widget.y ?? 0;
    const w = widget.width ?? 4;
    const h = widget.height ?? 2;

    for (let dx = 0; dx < w; dx++) {
      for (let dy = 0; dy < h; dy++) {
        occupiedCells.add(`${x + dx},${y + dy}`);
      }
    }
  }

  // Find first row with enough space
  for (let row = 0; row < 100; row++) {
    for (let col = 0; col <= GRID_COLUMNS - newWidth; col++) {
      let fits = true;

      for (let dx = 0; dx < newWidth && fits; dx++) {
        for (let dy = 0; dy < newHeight && fits; dy++) {
          if (occupiedCells.has(`${col + dx},${row + dy}`)) {
            fits = false;
          }
        }
      }

      if (fits) {
        return { x: col, y: row };
      }
    }
  }

  return { x: 0, y: 0 };
}

// ============================================
// Widget Palette Component
// ============================================

interface WidgetPaletteProps {
  widgets: AvailableWidget[];
  onAddWidget: (type: WidgetType) => void;
}

function WidgetPalette({ widgets, onAddWidget }: WidgetPaletteProps) {
  return (
    <div className="dashboard-editor__palette">
      <h3 className="dashboard-editor__palette-title">Add Widgets</h3>
      <div className="dashboard-editor__palette-list">
        {widgets.map((widget) => (
          <button
            key={widget.type}
            type="button"
            className="dashboard-editor__palette-item"
            onClick={() => onAddWidget(widget.type)}
            title={widget.description}
          >
            <span className="dashboard-editor__palette-icon">{widget.icon}</span>
            <span className="dashboard-editor__palette-label">{widget.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

// ============================================
// Widget Card Component
// ============================================

interface WidgetCardProps {
  widget: DashboardWidget;
  position: { left: number; top: number; width: number; height: number };
  isSelected: boolean;
  isDragging: boolean;
  onSelect: () => void;
  onDragStart: (e: React.MouseEvent) => void;
  onResizeStart: (e: React.MouseEvent, direction: 'e' | 's' | 'se') => void;
  onRemove: () => void;
  onConfigure: () => void;
}

function WidgetCard({
  widget,
  position,
  isSelected,
  isDragging,
  onSelect,
  onDragStart,
  onResizeStart,
  onRemove,
  onConfigure,
}: WidgetCardProps) {
  const typeIcons: Record<WidgetType, string> = {
    metric: '🔢',
    report: '📊',
    leaderboard: '🏆',
    activity_feed: '📋',
    tasks: '✅',
  };

  return (
    <div
      className={`dashboard-editor__widget ${
        isSelected ? 'dashboard-editor__widget--selected' : ''
      } ${isDragging ? 'dashboard-editor__widget--dragging' : ''}`}
      style={{
        left: position.left,
        top: position.top,
        width: position.width,
        height: position.height,
      }}
      onClick={(e) => {
        e.stopPropagation();
        onSelect();
      }}
      onMouseDown={(e) => {
        if (e.target === e.currentTarget || (e.target as HTMLElement).classList.contains('dashboard-editor__widget-header')) {
          onDragStart(e);
        }
      }}
    >
      <div className="dashboard-editor__widget-header">
        <span className="dashboard-editor__widget-icon">{typeIcons[widget.type]}</span>
        <span className="dashboard-editor__widget-title">{widget.title || widget.type}</span>
        <div className="dashboard-editor__widget-actions">
          <button
            type="button"
            className="dashboard-editor__widget-btn"
            onClick={(e) => {
              e.stopPropagation();
              onConfigure();
            }}
            title="Configure"
          >
            ⚙️
          </button>
          <button
            type="button"
            className="dashboard-editor__widget-btn"
            onClick={(e) => {
              e.stopPropagation();
              onRemove();
            }}
            title="Remove"
          >
            ✕
          </button>
        </div>
      </div>

      <div className="dashboard-editor__widget-content">
        <p className="dashboard-editor__widget-placeholder">
          {widget.type} widget
        </p>
      </div>

      {/* Resize handles */}
      {isSelected && (
        <>
          <div
            className="dashboard-editor__resize-handle dashboard-editor__resize-handle--e"
            onMouseDown={(e) => {
              e.stopPropagation();
              onResizeStart(e, 'e');
            }}
          />
          <div
            className="dashboard-editor__resize-handle dashboard-editor__resize-handle--s"
            onMouseDown={(e) => {
              e.stopPropagation();
              onResizeStart(e, 's');
            }}
          />
          <div
            className="dashboard-editor__resize-handle dashboard-editor__resize-handle--se"
            onMouseDown={(e) => {
              e.stopPropagation();
              onResizeStart(e, 'se');
            }}
          />
        </>
      )}
    </div>
  );
}

// ============================================
// Widget Configuration Modal
// ============================================

interface WidgetConfigModalProps {
  widget: DashboardWidget;
  onSave: (config: Partial<DashboardWidget>) => void;
  onCancel: () => void;
}

function WidgetConfigModal({ widget, onSave, onCancel }: WidgetConfigModalProps) {
  const [title, setTitle] = useState(widget.title || '');
  const [refreshIntervalMinutes, setRefreshIntervalMinutes] = useState(widget.refreshIntervalMinutes || 0);

  const handleSave = () => {
    onSave({
      title: title.trim() || undefined,
      refreshIntervalMinutes: refreshIntervalMinutes > 0 ? refreshIntervalMinutes : undefined,
    });
  };

  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="modal dashboard-editor__config-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Configure Widget</h3>
          <button type="button" className="modal-close" onClick={onCancel}>
            &times;
          </button>
        </div>

        <div className="modal-body">
          <div className="form-group">
            <label htmlFor="widget-title" className="form-label">
              Title
            </label>
            <input
              id="widget-title"
              type="text"
              className="form-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={`${widget.type} widget`}
            />
          </div>

          <div className="form-group">
            <label htmlFor="refresh-interval" className="form-label">
              Auto-refresh Interval (minutes)
            </label>
            <input
              id="refresh-interval"
              type="number"
              className="form-input"
              value={refreshIntervalMinutes || ''}
              onChange={(e) => setRefreshIntervalMinutes(Number(e.target.value))}
              min={0}
              max={60}
              placeholder="0 (disabled)"
            />
            <p className="form-hint">Set to 0 to disable auto-refresh</p>
          </div>
        </div>

        <div className="modal-footer">
          <button type="button" className="btn btn-ghost" onClick={onCancel}>
            Cancel
          </button>
          <button type="button" className="btn btn-primary" onClick={handleSave}>
            Save
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================
// Main Component
// ============================================

/**
 * DashboardEditor - Drag-and-drop dashboard layout editor
 *
 * Features:
 * - Drag widgets to reposition
 * - Resize widgets by dragging handles
 * - Add new widgets from palette
 * - Configure widget settings
 * - Grid-based snapping
 *
 * @example
 * ```tsx
 * <DashboardEditor
 *   dashboard={dashboard}
 *   availableWidgets={widgetTypes}
 *   onLayoutChange={handleLayoutChange}
 *   onWidgetAdd={handleWidgetAdd}
 *   onWidgetRemove={handleWidgetRemove}
 *   onWidgetConfigure={handleWidgetConfigure}
 *   onSave={handleSave}
 *   onCancel={handleCancel}
 * />
 * ```
 */
export function DashboardEditor({
  dashboard,
  availableWidgets = DEFAULT_AVAILABLE_WIDGETS,
  onLayoutChange,
  onWidgetAdd,
  onWidgetRemove,
  onWidgetConfigure,
  onSave,
  onCancel,
  isSaving = false,
}: DashboardEditorProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [containerWidth, setContainerWidth] = useState(0);

  const [selectedWidgetId, setSelectedWidgetId] = useState<string | null>(null);
  const [configWidgetId, setConfigWidgetId] = useState<string | null>(null);

  const [dragState, setDragState] = useState<DragState>({
    isDragging: false,
    widgetId: null,
    startX: 0,
    startY: 0,
    offsetX: 0,
    offsetY: 0,
  });

  const [resizeState, setResizeState] = useState<ResizeState>({
    isResizing: false,
    widgetId: null,
    direction: null,
    startX: 0,
    startY: 0,
    startWidth: 0,
    startHeight: 0,
  });

  // Measure container width
  useEffect(() => {
    const updateWidth = () => {
      if (containerRef.current) {
        setContainerWidth(containerRef.current.offsetWidth);
      }
    };

    updateWidth();
    window.addEventListener('resize', updateWidth);
    return () => window.removeEventListener('resize', updateWidth);
  }, []);

  // Grid calculations
  const columnWidth = containerWidth / GRID_COLUMNS;
  const gridHeight = useMemo(() => {
    const maxY = dashboard.widgets.reduce((max, widget) => {
      const y = (widget.y ?? 0) + (widget.height ?? 2);
      return Math.max(max, y);
    }, 4);
    return maxY * GRID_ROW_HEIGHT + GRID_ROW_HEIGHT * 2;
  }, [dashboard.widgets]);

  // Handle widget addition
  const handleAddWidget = useCallback(
    (type: WidgetType) => {
      const widgetDef = availableWidgets.find((w) => w.type === type);
      const width = widgetDef?.defaultWidth ?? 4;
      const height = widgetDef?.defaultHeight ?? 2;

      const position = findNextAvailablePosition(dashboard.widgets, width, height);

      const newWidget: Omit<DashboardWidget, 'id'> = {
        type,
        title: widgetDef?.label || type,
        x: position.x,
        y: position.y,
        width,
        height,
      };

      onWidgetAdd(newWidget);
    },
    [availableWidgets, dashboard.widgets, onWidgetAdd]
  );

  // Drag handlers
  const handleDragStart = useCallback(
    (widgetId: string, e: React.MouseEvent) => {
      const widget = dashboard.widgets.find((w) => w.id === widgetId);
      if (!widget) return;

      setDragState({
        isDragging: true,
        widgetId,
        startX: e.clientX,
        startY: e.clientY,
        offsetX: 0,
        offsetY: 0,
      });
      setSelectedWidgetId(widgetId);
    },
    [dashboard.widgets]
  );

  const handleDragMove = useCallback(
    (e: MouseEvent) => {
      if (!dragState.isDragging || !dragState.widgetId) return;

      const widget = dashboard.widgets.find((w) => w.id === dragState.widgetId);
      if (!widget) return;

      const dx = e.clientX - dragState.startX;
      const dy = e.clientY - dragState.startY;

      const newX = Math.max(0, Math.min(GRID_COLUMNS - (widget.width ?? 4), Math.round(((widget.x ?? 0) * columnWidth + dx) / columnWidth)));
      const newY = Math.max(0, Math.round(((widget.y ?? 0) * GRID_ROW_HEIGHT + dy) / GRID_ROW_HEIGHT));

      if (newX !== widget.x || newY !== widget.y) {
        const updatedWidgets = dashboard.widgets.map((w) =>
          w.id === widget.id ? { ...w, x: newX, y: newY } : w
        );
        onLayoutChange(updatedWidgets);
      }
    },
    [dragState, dashboard.widgets, columnWidth, onLayoutChange]
  );

  const handleDragEnd = useCallback(() => {
    setDragState({
      isDragging: false,
      widgetId: null,
      startX: 0,
      startY: 0,
      offsetX: 0,
      offsetY: 0,
    });
  }, []);

  // Resize handlers
  const handleResizeStart = useCallback(
    (widgetId: string, direction: 'e' | 's' | 'se', e: React.MouseEvent) => {
      const widget = dashboard.widgets.find((w) => w.id === widgetId);
      if (!widget) return;

      setResizeState({
        isResizing: true,
        widgetId,
        direction,
        startX: e.clientX,
        startY: e.clientY,
        startWidth: widget.width ?? 4,
        startHeight: widget.height ?? 2,
      });
    },
    [dashboard.widgets]
  );

  const handleResizeMove = useCallback(
    (e: MouseEvent) => {
      if (!resizeState.isResizing || !resizeState.widgetId) return;

      const widget = dashboard.widgets.find((w) => w.id === resizeState.widgetId);
      if (!widget) return;

      const dx = e.clientX - resizeState.startX;
      const dy = e.clientY - resizeState.startY;

      let newWidth = resizeState.startWidth;
      let newHeight = resizeState.startHeight;

      if (resizeState.direction === 'e' || resizeState.direction === 'se') {
        newWidth = Math.max(2, Math.min(GRID_COLUMNS - (widget.x ?? 0), Math.round((resizeState.startWidth * columnWidth + dx) / columnWidth)));
      }

      if (resizeState.direction === 's' || resizeState.direction === 'se') {
        newHeight = Math.max(2, Math.round((resizeState.startHeight * GRID_ROW_HEIGHT + dy) / GRID_ROW_HEIGHT));
      }

      if (newWidth !== widget.width || newHeight !== widget.height) {
        const updatedWidgets = dashboard.widgets.map((w) =>
          w.id === widget.id ? { ...w, width: newWidth, height: newHeight } : w
        );
        onLayoutChange(updatedWidgets);
      }
    },
    [resizeState, dashboard.widgets, columnWidth, onLayoutChange]
  );

  const handleResizeEnd = useCallback(() => {
    setResizeState({
      isResizing: false,
      widgetId: null,
      direction: null,
      startX: 0,
      startY: 0,
      startWidth: 0,
      startHeight: 0,
    });
  }, []);

  // Global mouse handlers
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (dragState.isDragging) {
        handleDragMove(e);
      } else if (resizeState.isResizing) {
        handleResizeMove(e);
      }
    };

    const handleMouseUp = () => {
      if (dragState.isDragging) {
        handleDragEnd();
      } else if (resizeState.isResizing) {
        handleResizeEnd();
      }
    };

    if (dragState.isDragging || resizeState.isResizing) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    }

    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [dragState.isDragging, resizeState.isResizing, handleDragMove, handleDragEnd, handleResizeMove, handleResizeEnd]);

  // Config widget
  const configWidget = configWidgetId
    ? dashboard.widgets.find((w) => w.id === configWidgetId)
    : null;

  return (
    <div className="dashboard-editor">
      {/* Header */}
      <div className="dashboard-editor__header">
        <h2 className="dashboard-editor__title">Edit Dashboard: {dashboard.name}</h2>
        <div className="dashboard-editor__actions">
          <button type="button" className="btn btn-ghost" onClick={onCancel}>
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={onSave}
            disabled={isSaving}
          >
            {isSaving ? 'Saving...' : 'Save Dashboard'}
          </button>
        </div>
      </div>

      <div className="dashboard-editor__layout">
        {/* Widget Palette */}
        <WidgetPalette widgets={availableWidgets} onAddWidget={handleAddWidget} />

        {/* Grid Canvas */}
        <div
          ref={containerRef}
          className="dashboard-editor__canvas"
          style={{ minHeight: gridHeight }}
          onClick={() => setSelectedWidgetId(null)}
        >
          {/* Grid lines */}
          <div className="dashboard-editor__grid">
            {Array.from({ length: GRID_COLUMNS }).map((_, i) => (
              <div
                key={i}
                className="dashboard-editor__grid-line"
                style={{ left: `${(i / GRID_COLUMNS) * 100}%` }}
              />
            ))}
          </div>

          {/* Widgets */}
          {dashboard.widgets.map((widget) => (
            <WidgetCard
              key={widget.id}
              widget={widget}
              position={getWidgetPosition(widget, containerWidth)}
              isSelected={selectedWidgetId === widget.id}
              isDragging={dragState.isDragging && dragState.widgetId === widget.id}
              onSelect={() => setSelectedWidgetId(widget.id)}
              onDragStart={(e) => handleDragStart(widget.id, e)}
              onResizeStart={(e, dir) => handleResizeStart(widget.id, dir, e)}
              onRemove={() => onWidgetRemove(widget.id)}
              onConfigure={() => setConfigWidgetId(widget.id)}
            />
          ))}

          {/* Empty state */}
          {dashboard.widgets.length === 0 && (
            <div className="dashboard-editor__empty">
              <p>No widgets yet. Add widgets from the palette on the left.</p>
            </div>
          )}
        </div>
      </div>

      {/* Config Modal */}
      {configWidget && (
        <WidgetConfigModal
          widget={configWidget}
          onSave={(config) => {
            onWidgetConfigure(configWidget.id, config);
            setConfigWidgetId(null);
          }}
          onCancel={() => setConfigWidgetId(null)}
        />
      )}
    </div>
  );
}

export default DashboardEditor;

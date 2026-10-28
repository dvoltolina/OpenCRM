/**
 * Dashboard Repository
 * Manages customizable dashboards with widgets for reporting analytics.
 *
 * HIPAA Compliance:
 * - Dashboards contain no PHI (configuration only)
 * - All operations require SecurityContext for businessId scoping
 * - Widget data is fetched separately with proper RBAC
 * - Audit log dashboard access with IDs only
 */

import { getDocs } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities, isOrgPrivileged } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type {
  Dashboard,
  DashboardWidget,
  DashboardLayout,
  WidgetType,
} from '../../types/reporting';

// ============================================
// Validation
// ============================================

const VALID_LAYOUTS: DashboardLayout[] = ['grid', 'freeform'];
const VALID_WIDGET_TYPES: WidgetType[] = ['report', 'metric', 'leaderboard', 'activity_feed', 'tasks'];

const dashboardValidator: Validator<Dashboard> = (data: Partial<Dashboard>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.name !== undefined && !data.name?.trim()) {
    errors.push({
      field: 'name',
      message: 'Dashboard name is required',
      code: 'REQUIRED',
    });
  }

  if (data.name && data.name.length > 100) {
    errors.push({
      field: 'name',
      message: 'Dashboard name must be 100 characters or less',
      code: 'MAX_LENGTH',
    });
  }

  if (data.layout !== undefined && !VALID_LAYOUTS.includes(data.layout)) {
    errors.push({
      field: 'layout',
      message: `Invalid layout. Must be one of: ${VALID_LAYOUTS.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.widgets !== undefined) {
    if (!Array.isArray(data.widgets)) {
      errors.push({
        field: 'widgets',
        message: 'Widgets must be an array',
        code: 'INVALID_TYPE',
      });
    } else {
      for (let i = 0; i < data.widgets.length; i++) {
        const widget = data.widgets[i];
        const widgetErrors = validateWidget(widget, i);
        errors.push(...widgetErrors);
      }
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

function validateWidget(
  widget: DashboardWidget,
  index: number
): Array<{ field: string; message: string; code: string }> {
  const errors: Array<{ field: string; message: string; code: string }> = [];
  const prefix = `widgets[${index}]`;

  if (!widget.id?.trim()) {
    errors.push({
      field: `${prefix}.id`,
      message: 'Widget ID is required',
      code: 'REQUIRED',
    });
  }

  if (!widget.type || !VALID_WIDGET_TYPES.includes(widget.type)) {
    errors.push({
      field: `${prefix}.type`,
      message: `Invalid widget type. Must be one of: ${VALID_WIDGET_TYPES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (!widget.title?.trim()) {
    errors.push({
      field: `${prefix}.title`,
      message: 'Widget title is required',
      code: 'REQUIRED',
    });
  }

  // Validate position
  if (typeof widget.x !== 'number' || widget.x < 0) {
    errors.push({
      field: `${prefix}.x`,
      message: 'Widget x position must be a non-negative number',
      code: 'INVALID_VALUE',
    });
  }

  if (typeof widget.y !== 'number' || widget.y < 0) {
    errors.push({
      field: `${prefix}.y`,
      message: 'Widget y position must be a non-negative number',
      code: 'INVALID_VALUE',
    });
  }

  if (typeof widget.width !== 'number' || widget.width <= 0) {
    errors.push({
      field: `${prefix}.width`,
      message: 'Widget width must be a positive number',
      code: 'INVALID_VALUE',
    });
  }

  if (typeof widget.height !== 'number' || widget.height <= 0) {
    errors.push({
      field: `${prefix}.height`,
      message: 'Widget height must be a positive number',
      code: 'INVALID_VALUE',
    });
  }

  // Validate type-specific config
  if (widget.type === 'report' && !widget.reportId) {
    errors.push({
      field: `${prefix}.reportId`,
      message: 'Report widget requires a reportId',
      code: 'REQUIRED',
    });
  }

  if (widget.type === 'metric' && !widget.metricConfig) {
    errors.push({
      field: `${prefix}.metricConfig`,
      message: 'Metric widget requires metricConfig',
      code: 'REQUIRED',
    });
  }

  if (widget.type === 'leaderboard' && !widget.leaderboardConfig) {
    errors.push({
      field: `${prefix}.leaderboardConfig`,
      message: 'Leaderboard widget requires leaderboardConfig',
      code: 'REQUIRED',
    });
  }

  return errors;
}

// ============================================
// Dashboard Repository
// ============================================

/**
 * Dashboard Repository
 * Handles CRUD operations for customizable dashboards with RBAC
 */
export class DashboardRepository extends ShareableRepository<Dashboard> {
  protected entityName = 'dashboard';
  protected sensitiveFields: Array<keyof Dashboard> = [];

  constructor() {
    super({ collectionName: 'dashboards' });
    this.setValidator(dashboardValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all dashboards accessible to the user
   */
  async getAccessible(context: SecurityContext): Promise<RepositoryResult<Dashboard[]>> {
    try {
      const result = await this.getAll(context, {
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!result.success) {
        return failedResult(result.error, 'Failed to get accessible dashboards');
      }

      await this.logAudit(context, 'list', null, {
        action: 'getAccessible',
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get accessible dashboards');
    }
  }

  /**
   * Get the default dashboard for the user's role
   */
  async getDefaultForRole(
    context: SecurityContext,
    role?: string
  ): Promise<RepositoryResult<Dashboard | null>> {
    try {
      const userRole = role || context.userRole;
      const collectionRef = this.getCollectionRef(context);

      // First, try to find a dashboard with defaultForRoles containing the user's role
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'isDefault', operator: '==', value: true },
        ],
        orderBy: { field: 'createdAt', direction: 'asc' },
        limit: 10,
      });

      const snapshot = await getDocs(q);
      const dashboards = this.filterAccessibleDashboards(
        context,
        this.snapshotToDashboards(snapshot)
      );

      // Find dashboard with matching role or generic default
      let matchingDashboard = dashboards.find(
        (d) => d.defaultForRoles?.includes(userRole)
      );

      // If no role-specific default, find any default dashboard
      if (!matchingDashboard) {
        matchingDashboard = dashboards.find(
          (d) => d.isDefault && (!d.defaultForRoles || d.defaultForRoles.length === 0)
        );
      }

      await this.logAudit(context, 'read', matchingDashboard?.id || null, {
        action: 'getDefaultForRole',
        role: userRole,
        found: Boolean(matchingDashboard),
      });

      return successResult(matchingDashboard || null);
    } catch (error) {
      return failedResult(error, 'Failed to get default dashboard');
    }
  }

  /**
   * Get public dashboards (visible to all in the business)
   */
  async getPublic(context: SecurityContext): Promise<RepositoryResult<Dashboard[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'isPublic', operator: '==', value: true }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const dashboards = this.snapshotToDashboards(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getPublic',
        count: dashboards.length,
      });

      return successResult(dashboards);
    } catch (error) {
      return failedResult(error, 'Failed to get public dashboards');
    }
  }

  /**
   * Get dashboards owned by the current user
   */
  async getMyDashboards(context: SecurityContext): Promise<RepositoryResult<Dashboard[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'ownerId', operator: '==', value: context.userId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const dashboards = this.snapshotToDashboards(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getMyDashboards',
        count: dashboards.length,
      });

      return successResult(dashboards);
    } catch (error) {
      return failedResult(error, 'Failed to get user dashboards');
    }
  }

  // ============================================
  // Widget Management
  // ============================================

  /**
   * Add a widget to a dashboard
   */
  async addWidget(
    context: SecurityContext,
    dashboardId: string,
    widget: DashboardWidget
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Validate widget
      const widgetErrors = validateWidget(widget, 0);
      if (widgetErrors.length > 0) {
        return failedResult(
          new InvalidArgumentError(widgetErrors.map((e) => e.message).join('; '), 'widget')
        );
      }

      // Get existing dashboard
      const existingResult = await this.getById(context, dashboardId);
      if (!existingResult.success) {
        return existingResult;
      }

      const dashboard = existingResult.data;

      // Check for duplicate widget ID
      if (dashboard.widgets.some((w) => w.id === widget.id)) {
        return failedResult(
          new InvalidArgumentError('Widget with this ID already exists', 'widget.id')
        );
      }

      // Add widget
      const updatedWidgets = [...dashboard.widgets, widget];
      const result = await this.update(context, dashboardId, { widgets: updatedWidgets });

      if (result.success) {
        await this.logAudit(context, 'update', dashboardId, {
          action: 'addWidget',
          widgetId: widget.id,
          widgetType: widget.type,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to add widget');
    }
  }

  /**
   * Update a widget in a dashboard
   */
  async updateWidget(
    context: SecurityContext,
    dashboardId: string,
    widgetId: string,
    updates: Partial<DashboardWidget>
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Get existing dashboard
      const existingResult = await this.getById(context, dashboardId);
      if (!existingResult.success) {
        return existingResult;
      }

      const dashboard = existingResult.data;
      const widgetIndex = dashboard.widgets.findIndex((w) => w.id === widgetId);

      if (widgetIndex === -1) {
        return failedResult(new InvalidArgumentError('Widget not found', 'widgetId'));
      }

      // Update widget
      const updatedWidget = { ...dashboard.widgets[widgetIndex], ...updates };
      const widgetErrors = validateWidget(updatedWidget, widgetIndex);
      if (widgetErrors.length > 0) {
        return failedResult(
          new InvalidArgumentError(widgetErrors.map((e) => e.message).join('; '), 'widget')
        );
      }

      const updatedWidgets = [...dashboard.widgets];
      updatedWidgets[widgetIndex] = updatedWidget;

      const result = await this.update(context, dashboardId, { widgets: updatedWidgets });

      if (result.success) {
        await this.logAudit(context, 'update', dashboardId, {
          action: 'updateWidget',
          widgetId,
          updatedFields: Object.keys(updates),
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to update widget');
    }
  }

  /**
   * Remove a widget from a dashboard
   */
  async removeWidget(
    context: SecurityContext,
    dashboardId: string,
    widgetId: string
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Get existing dashboard
      const existingResult = await this.getById(context, dashboardId);
      if (!existingResult.success) {
        return existingResult;
      }

      const dashboard = existingResult.data;
      const widgetIndex = dashboard.widgets.findIndex((w) => w.id === widgetId);

      if (widgetIndex === -1) {
        return failedResult(new InvalidArgumentError('Widget not found', 'widgetId'));
      }

      // Remove widget
      const updatedWidgets = dashboard.widgets.filter((w) => w.id !== widgetId);
      const result = await this.update(context, dashboardId, { widgets: updatedWidgets });

      if (result.success) {
        await this.logAudit(context, 'update', dashboardId, {
          action: 'removeWidget',
          widgetId,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to remove widget');
    }
  }

  /**
   * Reorder widgets in a dashboard
   */
  async reorderWidgets(
    context: SecurityContext,
    dashboardId: string,
    widgetPositions: Array<{ id: string; x: number; y: number; width?: number; height?: number }>
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Get existing dashboard
      const existingResult = await this.getById(context, dashboardId);
      if (!existingResult.success) {
        return existingResult;
      }

      const dashboard = existingResult.data;

      // Update widget positions
      const updatedWidgets = dashboard.widgets.map((widget) => {
        const newPosition = widgetPositions.find((p) => p.id === widget.id);
        if (newPosition) {
          return {
            ...widget,
            x: newPosition.x,
            y: newPosition.y,
            width: newPosition.width ?? widget.width,
            height: newPosition.height ?? widget.height,
          };
        }
        return widget;
      });

      const result = await this.update(context, dashboardId, { widgets: updatedWidgets });

      if (result.success) {
        await this.logAudit(context, 'update', dashboardId, {
          action: 'reorderWidgets',
          widgetCount: widgetPositions.length,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to reorder widgets');
    }
  }

  // ============================================
  // Default Dashboard Management
  // ============================================

  /**
   * Set a dashboard as the default for specific roles
   */
  async setAsDefault(
    context: SecurityContext,
    dashboardId: string,
    forRoles?: string[]
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Only admins/owners can set default dashboards
      if (!isOrgPrivileged(context)) {
        return failedResult(
          new AuthorizationError('Only admins can set default dashboards', 'setDefault', context.userRole)
        );
      }

      // If setting as default, unset other defaults for the same roles
      if (forRoles && forRoles.length > 0) {
        const collectionRef = this.getCollectionRef(context);
        const q = buildQuery(collectionRef, {
          where: [{ field: 'isDefault', operator: '==', value: true }],
        });

        const snapshot = await getDocs(q);
        const existingDefaults = this.snapshotToDashboards(snapshot);

        for (const existing of existingDefaults) {
          if (existing.id !== dashboardId && existing.defaultForRoles) {
            const remainingRoles = existing.defaultForRoles.filter(
              (role) => !forRoles.includes(role)
            );
            if (remainingRoles.length !== existing.defaultForRoles.length) {
              await this.update(context, existing.id, {
                defaultForRoles: remainingRoles,
                isDefault: remainingRoles.length > 0,
              });
            }
          }
        }
      }

      const result = await this.update(context, dashboardId, {
        isDefault: true,
        defaultForRoles: forRoles || [],
      });

      if (result.success) {
        await this.logAudit(context, 'update', dashboardId, {
          action: 'setAsDefault',
          forRoles,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to set dashboard as default');
    }
  }

  /**
   * Remove default status from a dashboard
   */
  async removeDefault(
    context: SecurityContext,
    dashboardId: string
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Only admins/owners can modify default dashboards
      if (!isOrgPrivileged(context)) {
        return failedResult(
          new AuthorizationError('Only admins can modify default dashboards', 'removeDefault', context.userRole)
        );
      }

      const result = await this.update(context, dashboardId, {
        isDefault: false,
        defaultForRoles: [],
      });

      if (result.success) {
        await this.logAudit(context, 'update', dashboardId, {
          action: 'removeDefault',
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to remove default status');
    }
  }

  // ============================================
  // Duplicate Dashboard
  // ============================================

  /**
   * Duplicate an existing dashboard
   */
  async duplicate(
    context: SecurityContext,
    dashboardId: string,
    newName?: string
  ): Promise<RepositoryResult<Dashboard>> {
    try {
      if (!isValidDocumentId(dashboardId)) {
        return failedResult(new InvalidArgumentError('Invalid dashboard ID', 'dashboardId'));
      }

      // Get existing dashboard
      const existingResult = await this.getById(context, dashboardId);
      if (!existingResult.success) {
        return existingResult;
      }

      const source = existingResult.data;

      // Create new dashboard with duplicated config
      const duplicateData: Omit<Dashboard, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        name: newName || `${source.name} (Copy)`,
        description: source.description,
        widgets: source.widgets.map((w) => ({
          ...w,
          id: `${w.id}-copy-${Date.now()}`,
        })),
        layout: source.layout,
        isDefault: false, // Don't copy default status
        defaultForRoles: undefined,
        ownerId: context.userId,
        ownerName: context.userName,
        isPublic: false, // Don't copy public status
        teamIds: context.teamIds || [],
        visibility: 'team',
      };

      const result = await this.create(context, duplicateData);

      if (result.success) {
        await this.logAudit(context, 'create', result.data.id, {
          action: 'duplicate',
          sourceDashboardId: dashboardId,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to duplicate dashboard');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleDashboards(context: SecurityContext, dashboards: Dashboard[]): Dashboard[] {
    return filterAuthorizedEntities(context, dashboards, this.sensitiveFields);
  }

  /**
   * Convert Firestore snapshot to Dashboard array
   */
  private snapshotToDashboards(snapshot: QuerySnapshot<DocumentData>): Dashboard[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        businessId: data.businessId as string,
        name: data.name as string,
        description: data.description as string | undefined,
        widgets: (data.widgets as DashboardWidget[]) || [],
        layout: (data.layout as DashboardLayout) || 'grid',
        isDefault: data.isDefault as boolean || false,
        defaultForRoles: data.defaultForRoles as string[] | undefined,
        ownerId: data.ownerId as string,
        ownerName: data.ownerName as string | undefined,
        isPublic: data.isPublic as boolean || false,
        teamIds: (data.teamIds as string[]) || [],
        visibility: data.visibility || 'team',
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// ============================================
// Export singleton instance
// ============================================

let dashboardRepository: DashboardRepository | null = null;

export function getDashboardRepository(): DashboardRepository {
  if (!dashboardRepository) {
    dashboardRepository = new DashboardRepository();
  }
  return dashboardRepository;
}

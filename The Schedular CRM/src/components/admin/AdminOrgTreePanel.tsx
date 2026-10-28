/**
 * AdminOrgTreePanel Component
 * Hierarchical org tree view showing managers and their team members
 *
 * Per AGENT_RULES: Components should be under 600 lines
 */

import { useState, useMemo } from 'react';
import { useTeamMembers } from '../../hooks/useTeamMembers';
import { useTeams } from '../../hooks/useTeams';
import type { TeamMember } from '../../hooks/useTeamMembers';
import './admin.css';

interface AdminOrgTreePanelProps {
  onUserSelect: (user: TeamMember) => void;
}

interface OrgNode {
  user: TeamMember;
  children: OrgNode[];
  teamNames: string[];
}

const ROLE_LABELS: Record<string, string> = {
  owner: 'Owner',
  admin: 'Admin',
  manager: 'Manager',
  staff: 'Staff',
  sales: 'Sales',
  provider: 'Provider',
  frontDesk: 'Front Desk',
};

const ROLE_ORDER: Record<string, number> = {
  owner: 0,
  admin: 1,
  manager: 2,
  sales: 3,
  staff: 4,
  provider: 5,
  frontDesk: 6,
};

function OrgTreeNode({
  node,
  level,
  onUserSelect,
}: {
  node: OrgNode;
  level: number;
  onUserSelect: (user: TeamMember) => void;
}) {
  const [expanded, setExpanded] = useState(true);
  const hasChildren = node.children.length > 0;

  return (
    <div className="org-tree-node" style={{ marginLeft: level > 0 ? '1.5rem' : 0 }}>
      <div
        className="org-tree-node-header"
        onClick={() => onUserSelect(node.user)}
      >
        <span
          className="org-tree-expand-icon"
          onClick={(e) => {
            e.stopPropagation();
            if (hasChildren) setExpanded(!expanded);
          }}
          style={{ cursor: hasChildren ? 'pointer' : 'default' }}
        >
          {hasChildren ? (expanded ? '▼' : '▶') : '•'}
        </span>
        <div className="org-tree-user-info">
          <div className="org-tree-user-name">{node.user.displayName}</div>
          <div className="org-tree-user-role">
            {ROLE_LABELS[node.user.role] || node.user.role}
            {node.teamNames.length > 0 && ` · ${node.teamNames.join(', ')}`}
          </div>
        </div>
        <span
          className={`admin-status-badge ${node.user.isActive ? 'active' : 'inactive'}`}
          style={{ marginLeft: 'auto' }}
        >
          {node.user.isActive ? 'Active' : 'Inactive'}
        </span>
      </div>
      {hasChildren && expanded && (
        <div className="org-tree-children">
          {node.children.map((child) => (
            <OrgTreeNode
              key={child.user.id}
              node={child}
              level={level + 1}
              onUserSelect={onUserSelect}
            />
          ))}
        </div>
      )}
    </div>
  );
}

export function AdminOrgTreePanel({ onUserSelect }: AdminOrgTreePanelProps) {
  const { members, isLoading, error } = useTeamMembers();
  const { teams } = useTeams();

  // Create a map of team IDs to team names
  const teamMap = useMemo(() => {
    const map: Record<string, string> = {};
    teams.forEach((team) => {
      map[team.id] = team.name;
    });
    return map;
  }, [teams]);

  // Build org tree
  const orgTree = useMemo(() => {
    // Create a map of user IDs to their children
    const childrenMap: Record<string, TeamMember[]> = {};
    const rootUsers: TeamMember[] = [];

    members.forEach((member) => {
      if (member.managerId) {
        if (!childrenMap[member.managerId]) {
          childrenMap[member.managerId] = [];
        }
        childrenMap[member.managerId].push(member);
      } else if (member.role === 'owner' || member.role === 'admin' || member.role === 'manager') {
        // Users without managers but with leadership roles are root nodes
        rootUsers.push(member);
      }
    });

    // Also add staff without managers to root
    members.forEach((member) => {
      if (!member.managerId && !rootUsers.includes(member)) {
        rootUsers.push(member);
      }
    });

    // Remove duplicates
    const uniqueRootUsers = [...new Set(rootUsers)];

    // Build tree recursively
    const buildNode = (user: TeamMember): OrgNode => {
      const children = (childrenMap[user.id] || [])
        .sort((a, b) => {
          const roleA = ROLE_ORDER[a.role] ?? 99;
          const roleB = ROLE_ORDER[b.role] ?? 99;
          if (roleA !== roleB) return roleA - roleB;
          return a.displayName.localeCompare(b.displayName);
        })
        .map(buildNode);

      const teamNames = user.managedTeamIds
        ?.map((id) => teamMap[id])
        .filter(Boolean) as string[] || [];

      return { user, children, teamNames };
    };

    // Sort root users by role, then by name
    const sortedRoots = uniqueRootUsers.sort((a, b) => {
      const roleA = ROLE_ORDER[a.role] ?? 99;
      const roleB = ROLE_ORDER[b.role] ?? 99;
      if (roleA !== roleB) return roleA - roleB;
      return a.displayName.localeCompare(b.displayName);
    });

    return sortedRoots.map(buildNode);
  }, [members, teamMap]);

  // Stats
  const stats = useMemo(() => {
    const managersWithTeams = members.filter(
      (m) => m.managedTeamIds && m.managedTeamIds.length > 0
    ).length;
    const unassignedTeamMembers = members.filter(
      (m) => !m.managerId && !['owner', 'admin', 'manager'].includes(m.role)
    ).length;
    return {
      totalPeople: members.length,
      managersWithTeams,
      teams: teams.length,
      unassignedTeamMembers,
    };
  }, [members, teams]);

  if (isLoading) {
    return <div className="admin-loading">Loading organization...</div>;
  }

  if (error) {
    return (
      <div className="admin-empty-state">
        <div className="admin-empty-state-title">Error loading organization</div>
        <p>{error.message}</p>
      </div>
    );
  }

  return (
    <div className="admin-panel">
      <div className="admin-stats-grid">
        <div className="admin-stat-card admin-stat-card--accent">
          <div className="admin-stat-label">People</div>
          <div className="admin-stat-value">{stats.totalPeople}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--subtle">
          <div className="admin-stat-label">Teams</div>
          <div className="admin-stat-value">{stats.teams}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--warm">
          <div className="admin-stat-label">Managers with Teams</div>
          <div className="admin-stat-value">{stats.managersWithTeams}</div>
        </div>
        <div className="admin-stat-card">
          <div className="admin-stat-label">Unassigned Team Members</div>
          <div className="admin-stat-value">{stats.unassignedTeamMembers}</div>
        </div>
      </div>

      <div className="admin-panel-surface">
        <div className="admin-panel-header">
          <div className="admin-panel-title-group">
            <p className="admin-panel-eyebrow">Reporting Structure</p>
            <h2 className="admin-panel-title">Organization Hierarchy</h2>
            <p className="admin-panel-description">
              Review reporting lines, manager coverage, and unassigned contributors.
            </p>
          </div>
        </div>

        {orgTree.length === 0 ? (
          <div className="admin-empty-state">
            <div className="admin-empty-state-icon">🏢</div>
            <div className="admin-empty-state-title">No organization data</div>
            <p>Add team members to see the organization structure.</p>
          </div>
        ) : (
          <div className="org-tree">
            {orgTree.map((node) => (
              <OrgTreeNode
                key={node.user.id}
                node={node}
                level={0}
                onUserSelect={onUserSelect}
              />
            ))}
          </div>
        )}

        <div className="admin-note">
          Click any user to open their detail drawer with leads, deals, and activity history.
        </div>
      </div>
    </div>
  );
}

export default AdminOrgTreePanel;

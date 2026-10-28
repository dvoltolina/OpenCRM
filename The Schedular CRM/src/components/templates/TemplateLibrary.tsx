/**
 * TemplateLibrary Component
 * Browse, search, and manage form templates
 *
 * Agent CRM-30 Implementation
 */

import { useState } from 'react';
import { useTemplates, useTemplateMutations } from '../../hooks/useTemplates';
import type { FormTemplate, TemplateCategory, TemplateFilter } from '../../types/templates';
import './templates.css';

interface TemplateLibraryProps {
  onSelectTemplate?: (template: FormTemplate) => void;
  onEditTemplate?: (template: FormTemplate) => void;
  showActions?: boolean;
}

export function TemplateLibrary({
  onSelectTemplate,
  onEditTemplate,
  showActions = true,
}: TemplateLibraryProps) {
  const [_filter, _setFilter] = useState<TemplateFilter>({ isActive: true });
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<TemplateCategory | 'all'>('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  const { templates, isLoading, error, refresh } = useTemplates({
    ..._filter,
    searchTerm: searchTerm || undefined,
    category: selectedCategory !== 'all' ? selectedCategory : undefined,
  });

  const { deleteTemplate, cloneTemplate, isLoading: isMutating } = useTemplateMutations();

  const handleCategoryChange = (category: TemplateCategory | 'all') => {
    setSelectedCategory(category);
  };

  const handleSearch = (term: string) => {
    setSearchTerm(term);
  };

  const handleClone = async (template: FormTemplate) => {
    try {
      const newName = `${template.name} (Copy)`;
      await cloneTemplate(template.id, newName);
      refresh();
    } catch (err) {
      console.error('Failed to clone template:', err);
    }
  };

  const handleDelete = async (template: FormTemplate) => {
    if (!confirm(`Are you sure you want to delete "${template.name}"?`)) {
      return;
    }

    try {
      await deleteTemplate(template.id);
      refresh();
    } catch (err) {
      console.error('Failed to delete template:', err);
    }
  };

  // Toggle active functionality to be implemented with updateTemplate from mutations
  // const handleToggleActive = async (_template: FormTemplate) => {
  //   // TODO: Implement with updateTemplate from mutations
  // };

  if (error) {
    return (
      <div className="template-library-error">
        <p>Error loading templates: {error.message}</p>
        <button onClick={refresh}>Retry</button>
      </div>
    );
  }

  return (
    <div className="template-library">
      <div className="template-library-header">
        <h2>Template Library</h2>
        <div className="template-library-controls">
          <div className="template-search">
            <input
              type="text"
              placeholder="Search templates..."
              value={searchTerm}
              onChange={(e) => handleSearch(e.target.value)}
              className="template-search-input"
            />
          </div>

          <div className="template-view-toggle">
            <button
              className={viewMode === 'grid' ? 'active' : ''}
              onClick={() => setViewMode('grid')}
              title="Grid view"
            >
              Grid
            </button>
            <button
              className={viewMode === 'list' ? 'active' : ''}
              onClick={() => setViewMode('list')}
              title="List view"
            >
              List
            </button>
          </div>
        </div>
      </div>

      <div className="template-library-filters">
        <button
          className={`filter-btn ${selectedCategory === 'all' ? 'active' : ''}`}
          onClick={() => handleCategoryChange('all')}
        >
          All Templates
        </button>
        <button
          className={`filter-btn ${selectedCategory === 'therapy' ? 'active' : ''}`}
          onClick={() => handleCategoryChange('therapy')}
        >
          Therapy
        </button>
        <button
          className={`filter-btn ${selectedCategory === 'real_estate' ? 'active' : ''}`}
          onClick={() => handleCategoryChange('real_estate')}
        >
          Real Estate
        </button>
        <button
          className={`filter-btn ${selectedCategory === 'accounting' ? 'active' : ''}`}
          onClick={() => handleCategoryChange('accounting')}
        >
          Accounting
        </button>
        <button
          className={`filter-btn ${selectedCategory === 'custom' ? 'active' : ''}`}
          onClick={() => handleCategoryChange('custom')}
        >
          Custom
        </button>
      </div>

      {isLoading ? (
        <div className="template-library-loading">Loading templates...</div>
      ) : templates.length === 0 ? (
        <div className="template-library-empty">
          <p>No templates found</p>
          {searchTerm && <p>Try adjusting your search or filters</p>}
        </div>
      ) : (
        <div className={`template-library-content ${viewMode}`}>
          {templates.map((template) => (
            <TemplateCard
              key={template.id}
              template={template}
              viewMode={viewMode}
              onSelect={onSelectTemplate}
              onEdit={onEditTemplate}
              onClone={handleClone}
              onDelete={handleDelete}
              showActions={showActions}
              isDeleting={isMutating}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================
// TemplateCard Component
// ============================================

interface TemplateCardProps {
  template: FormTemplate;
  viewMode: 'grid' | 'list';
  onSelect?: (template: FormTemplate) => void;
  onEdit?: (template: FormTemplate) => void;
  onClone: (template: FormTemplate) => void;
  onDelete: (template: FormTemplate) => void;
  showActions: boolean;
  isDeleting: boolean;
}

function TemplateCard({
  template,
  viewMode,
  onSelect,
  onEdit,
  onClone,
  onDelete,
  showActions,
  isDeleting,
}: TemplateCardProps) {
  const getCategoryBadgeClass = (category: TemplateCategory) => {
    const baseClass = 'template-category-badge';
    return `${baseClass} ${baseClass}-${category}`;
  };

  const formatCategoryName = (category: TemplateCategory) => {
    switch (category) {
      case 'therapy':
        return 'Therapy';
      case 'real_estate':
        return 'Real Estate';
      case 'accounting':
        return 'Accounting';
      case 'custom':
        return 'Custom';
      default:
        return category;
    }
  };

  return (
    <div className={`template-card ${viewMode}`}>
      <div className="template-card-header">
        <h3 className="template-card-title">{template.name}</h3>
        <span className={getCategoryBadgeClass(template.category)}>
          {formatCategoryName(template.category)}
        </span>
      </div>

      {template.description && (
        <p className="template-card-description">{template.description}</p>
      )}

      <div className="template-card-meta">
        <span className="template-card-field-count">{template.fields.length} fields</span>
        <span className="template-card-usage">Used {template.usageCount} times</span>
        {template.isSystem && <span className="template-card-system-badge">System</span>}
      </div>

      {template.tags.length > 0 && (
        <div className="template-card-tags">
          {template.tags.map((tag) => (
            <span key={tag} className="template-tag">
              {tag}
            </span>
          ))}
        </div>
      )}

      {showActions && (
        <div className="template-card-actions">
          {onSelect && (
            <button className="btn btn-primary btn-sm" onClick={() => onSelect(template)}>
              Use Template
            </button>
          )}
          {onEdit && (
            <button className="btn btn-secondary btn-sm" onClick={() => onEdit(template)}>
              Edit
            </button>
          )}
          <button
            className="btn btn-secondary btn-sm"
            onClick={() => onClone(template)}
            disabled={isDeleting}
          >
            Clone
          </button>
          {!template.isSystem && (
            <button
              className="btn btn-danger btn-sm"
              onClick={() => onDelete(template)}
              disabled={isDeleting}
            >
              Delete
            </button>
          )}
        </div>
      )}
    </div>
  );
}

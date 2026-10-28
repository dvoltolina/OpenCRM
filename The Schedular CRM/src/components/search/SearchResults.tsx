/**
 * SearchResults Component
 * Displays grouped search results by entity type
 *
 * Agent CRM-26 Implementation
 */

import { useNavigate } from 'react-router-dom';
import type { GroupedSearchResults, SearchResult } from '../../hooks/useGlobalSearch';
import './search.css';

// ============================================
// Types
// ============================================

export interface SearchResultsProps {
  /** Grouped search results */
  results: GroupedSearchResults;
  /** Currently selected result index (for keyboard navigation) */
  selectedIndex: number;
  /** Callback when a result is clicked */
  onResultClick: (result: SearchResult) => void;
  /** Whether search is in progress */
  isSearching: boolean;
  /** Search query */
  query: string;
}

// ============================================
// Helpers
// ============================================

function getEntityIcon(type: SearchResult['type']): string {
  const icons = {
    lead: '👤',
    deal: '💼',
    contact: '👥',
    company: '🏢',
  };
  return icons[type];
}

function getEntityLabel(type: SearchResult['type']): string {
  const labels = {
    lead: 'Leads',
    deal: 'Deals',
    contact: 'Contacts',
    company: 'Companies',
  };
  return labels[type];
}

function getNavigationPath(result: SearchResult): string {
  const paths = {
    lead: '/leads',
    deal: '/deals',
    contact: '/contacts',
    company: '/companies',
  };
  return `${paths[result.type]}?id=${result.id}`;
}

// ============================================
// Component
// ============================================

/**
 * SearchResults - Display grouped search results
 *
 * @example
 * ```tsx
 * <SearchResults
 *   results={results}
 *   selectedIndex={selectedIndex}
 *   onResultClick={handleResultClick}
 *   isSearching={isSearching}
 *   query={query}
 * />
 * ```
 */
export function SearchResults({
  results,
  selectedIndex,
  onResultClick,
  isSearching,
  query,
}: SearchResultsProps) {
  const navigate = useNavigate();

  const handleResultClick = (result: SearchResult) => {
    onResultClick(result);
    navigate(getNavigationPath(result));
  };

  // Flatten results for keyboard navigation
  const allResults: SearchResult[] = [
    ...results.leads,
    ...results.deals,
    ...results.contacts,
    ...results.companies,
  ];

  const totalResults = allResults.length;

  if (isSearching) {
    return (
      <div className="search-results">
        <div className="search-results__loading">Searching...</div>
      </div>
    );
  }

  if (!query.trim()) {
    return null;
  }

  if (totalResults === 0) {
    return (
      <div className="search-results">
        <div className="search-results__empty">
          <p>No results found for "{query}"</p>
          <p className="search-results__empty-hint">
            Try searching by name, email, company, or title
          </p>
        </div>
      </div>
    );
  }

  let currentIndex = 0;

  return (
    <div className="search-results">
      <div className="search-results__header">
        <span className="search-results__count">
          {totalResults} result{totalResults !== 1 ? 's' : ''}
        </span>
      </div>

      {results.leads.length > 0 && (
        <div className="search-results__group">
          <div className="search-results__group-title">
            <span className="search-results__group-icon">{getEntityIcon('lead')}</span>
            {getEntityLabel('lead')} ({results.leads.length})
          </div>
          <div className="search-results__items">
            {results.leads.map((result) => {
              const isSelected = currentIndex === selectedIndex;
              const index = currentIndex++;
              return (
                <button
                  key={result.id}
                  type="button"
                  className={`search-result-item ${isSelected ? 'search-result-item--selected' : ''}`}
                  onClick={() => handleResultClick(result)}
                  data-index={index}
                >
                  <div className="search-result-item__content">
                    <div className="search-result-item__title">{result.title}</div>
                    {result.subtitle && (
                      <div className="search-result-item__subtitle">{result.subtitle}</div>
                    )}
                  </div>
                  {result.metadata && (
                    <div className="search-result-item__metadata">{result.metadata}</div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}

      {results.deals.length > 0 && (
        <div className="search-results__group">
          <div className="search-results__group-title">
            <span className="search-results__group-icon">{getEntityIcon('deal')}</span>
            {getEntityLabel('deal')} ({results.deals.length})
          </div>
          <div className="search-results__items">
            {results.deals.map((result) => {
              const isSelected = currentIndex === selectedIndex;
              const index = currentIndex++;
              return (
                <button
                  key={result.id}
                  type="button"
                  className={`search-result-item ${isSelected ? 'search-result-item--selected' : ''}`}
                  onClick={() => handleResultClick(result)}
                  data-index={index}
                >
                  <div className="search-result-item__content">
                    <div className="search-result-item__title">{result.title}</div>
                    {result.subtitle && (
                      <div className="search-result-item__subtitle">{result.subtitle}</div>
                    )}
                  </div>
                  {result.metadata && (
                    <div className="search-result-item__metadata">{result.metadata}</div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}

      {results.contacts.length > 0 && (
        <div className="search-results__group">
          <div className="search-results__group-title">
            <span className="search-results__group-icon">{getEntityIcon('contact')}</span>
            {getEntityLabel('contact')} ({results.contacts.length})
          </div>
          <div className="search-results__items">
            {results.contacts.map((result) => {
              const isSelected = currentIndex === selectedIndex;
              const index = currentIndex++;
              return (
                <button
                  key={result.id}
                  type="button"
                  className={`search-result-item ${isSelected ? 'search-result-item--selected' : ''}`}
                  onClick={() => handleResultClick(result)}
                  data-index={index}
                >
                  <div className="search-result-item__content">
                    <div className="search-result-item__title">{result.title}</div>
                    {result.subtitle && (
                      <div className="search-result-item__subtitle">{result.subtitle}</div>
                    )}
                  </div>
                  {result.metadata && (
                    <div className="search-result-item__metadata">{result.metadata}</div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}

      {results.companies.length > 0 && (
        <div className="search-results__group">
          <div className="search-results__group-title">
            <span className="search-results__group-icon">{getEntityIcon('company')}</span>
            {getEntityLabel('company')} ({results.companies.length})
          </div>
          <div className="search-results__items">
            {results.companies.map((result) => {
              const isSelected = currentIndex === selectedIndex;
              const index = currentIndex++;
              return (
                <button
                  key={result.id}
                  type="button"
                  className={`search-result-item ${isSelected ? 'search-result-item--selected' : ''}`}
                  onClick={() => handleResultClick(result)}
                  data-index={index}
                >
                  <div className="search-result-item__content">
                    <div className="search-result-item__title">{result.title}</div>
                    {result.subtitle && (
                      <div className="search-result-item__subtitle">{result.subtitle}</div>
                    )}
                  </div>
                  {result.metadata && (
                    <div className="search-result-item__metadata">{result.metadata}</div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

export default SearchResults;

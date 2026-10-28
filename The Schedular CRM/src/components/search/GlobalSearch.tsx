/**
 * GlobalSearch Component
 * Global search bar with dropdown results
 *
 * Agent CRM-26 Implementation
 * Dependencies: CRM-08 to CRM-10 hooks
 */

import React, { useState, useRef, useEffect } from 'react';
import { useGlobalSearch, type SearchResult } from '../../hooks/useGlobalSearch';
import { SearchResults } from './SearchResults';
import './search.css';

// ============================================
// Types
// ============================================

export interface GlobalSearchProps {
  /** Placeholder text for search input */
  placeholder?: string;
  /** Additional CSS classes */
  className?: string;
  /** Whether to show the search dropdown */
  autoFocus?: boolean;
}

// ============================================
// Component
// ============================================

/**
 * GlobalSearch - Global search bar with results dropdown
 *
 * Features:
 * - Debounced search across all entities
 * - Keyboard navigation (Arrow Up/Down, Enter, Escape)
 * - Click outside to close
 * - Clear button
 *
 * @example
 * ```tsx
 * <GlobalSearch
 *   placeholder="Search leads, deals, contacts..."
 *   autoFocus={false}
 * />
 * ```
 */
export function GlobalSearch({
  placeholder = 'Search leads, deals, contacts, companies...',
  className = '',
  autoFocus = false,
}: GlobalSearchProps) {
  const { query, setQuery, results, isSearching, hasResults, clear } = useGlobalSearch();
  const [isOpen, setIsOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const searchRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Auto focus on mount if requested
  useEffect(() => {
    if (autoFocus && inputRef.current) {
      inputRef.current.focus();
    }
  }, [autoFocus]);

  // Open dropdown when there are results
  useEffect(() => {
    if (hasResults || (query.trim() && !isSearching)) {
      setIsOpen(true);
      setSelectedIndex(0);
    } else {
      setIsOpen(false);
    }
  }, [hasResults, query, isSearching]);

  // Close dropdown on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  // Get all results as flat array for navigation
  const allResults: SearchResult[] = [
    ...results.leads,
    ...results.deals,
    ...results.contacts,
    ...results.companies,
  ];

  // Keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (!isOpen) return;

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex((prev) => (prev < allResults.length - 1 ? prev + 1 : prev));
        break;

      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex((prev) => (prev > 0 ? prev - 1 : 0));
        break;

      case 'Enter':
        e.preventDefault();
        if (allResults[selectedIndex]) {
          handleResultClick(allResults[selectedIndex]);
        }
        break;

      case 'Escape':
        e.preventDefault();
        handleClear();
        inputRef.current?.blur();
        break;

      default:
        break;
    }
  };

  // Handle input change
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value);
    setSelectedIndex(0);
  };

  // Handle result click
  const handleResultClick = (_result: SearchResult) => {
    setIsOpen(false);
    clear();
  };

  // Handle clear
  const handleClear = () => {
    clear();
    setIsOpen(false);
    setSelectedIndex(0);
    inputRef.current?.focus();
  };

  // Handle input focus
  const handleInputFocus = () => {
    if (hasResults || (query.trim() && !isSearching)) {
      setIsOpen(true);
    }
  };

  return (
    <div className={`global-search ${className}`} ref={searchRef}>
      <div className="global-search__input-wrapper">
        <svg
          className="global-search__icon"
          width="20"
          height="20"
          viewBox="0 0 20 20"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M9 17C13.4183 17 17 13.4183 17 9C17 4.58172 13.4183 1 9 1C4.58172 1 1 4.58172 1 9C1 13.4183 4.58172 17 9 17Z"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M19 19L14.65 14.65"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        <input
          ref={inputRef}
          type="text"
          className="global-search__input"
          placeholder={placeholder}
          value={query}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          onFocus={handleInputFocus}
          aria-label="Global search"
          aria-autocomplete="list"
          aria-controls="search-results"
          aria-expanded={isOpen}
        />
        {query && (
          <button
            type="button"
            className="global-search__clear"
            onClick={handleClear}
            aria-label="Clear search"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 16 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M12 4L4 12M4 4L12 12"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        )}
        {isSearching && (
          <div className="global-search__spinner" aria-label="Searching">
            <svg
              className="global-search__spinner-icon"
              width="20"
              height="20"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <circle
                cx="10"
                cy="10"
                r="8"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeDasharray="50"
                strokeDashoffset="25"
              />
            </svg>
          </div>
        )}
      </div>

      {isOpen && (
        <div className="global-search__dropdown" id="search-results">
          <SearchResults
            results={results}
            selectedIndex={selectedIndex}
            onResultClick={handleResultClick}
            isSearching={isSearching}
            query={query}
          />
        </div>
      )}

      {isOpen && (
        <div className="global-search__hints">
          <span className="global-search__hint">
            <kbd>↑</kbd>
            <kbd>↓</kbd> to navigate
          </span>
          <span className="global-search__hint">
            <kbd>↵</kbd> to select
          </span>
          <span className="global-search__hint">
            <kbd>esc</kbd> to close
          </span>
        </div>
      )}
    </div>
  );
}

export default GlobalSearch;

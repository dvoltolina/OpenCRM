/**
 * GlobalSearch Component Tests
 * Agent CRM-26 Implementation
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import { GlobalSearch } from '../GlobalSearch';
import { useGlobalSearch } from '../../../hooks/useGlobalSearch';

// Mock the useGlobalSearch hook
vi.mock('../../../hooks/useGlobalSearch');

const mockUseGlobalSearch = vi.mocked(useGlobalSearch);

// Mock component wrapper
function TestWrapper({ children }: { children: React.ReactNode }) {
  return <BrowserRouter>{children}</BrowserRouter>;
}

describe('GlobalSearch', () => {
  const mockSetQuery = vi.fn();
  const mockClear = vi.fn();

  const mockResults = {
    leads: [
      {
        id: 'lead-1',
        type: 'lead' as const,
        title: 'John Doe',
        subtitle: 'john@example.com',
        metadata: 'qualified',
      },
    ],
    deals: [
      {
        id: 'deal-1',
        type: 'deal' as const,
        title: 'Enterprise Deal',
        subtitle: 'Acme Corp',
        metadata: '$50,000',
      },
    ],
    contacts: [
      {
        id: 'contact-1',
        type: 'contact' as const,
        title: 'Jane Smith',
        subtitle: 'jane@example.com',
        metadata: 'customer',
      },
    ],
    companies: [
      {
        id: 'company-1',
        type: 'company' as const,
        title: 'Tech Startup Inc',
        subtitle: 'Technology',
        metadata: 'medium',
      },
    ],
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mockUseGlobalSearch.mockReturnValue({
      query: '',
      setQuery: mockSetQuery,
      results: {
        leads: [],
        deals: [],
        contacts: [],
        companies: [],
      },
      isSearching: false,
      totalResults: 0,
      hasResults: false,
      clear: mockClear,
    });
  });

  describe('Rendering', () => {
    it('renders search input', () => {
      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByPlaceholderText(/search leads, deals, contacts/i)).toBeInTheDocument();
    });

    it('renders with custom placeholder', () => {
      render(
        <TestWrapper>
          <GlobalSearch placeholder="Custom search placeholder" />
        </TestWrapper>
      );

      expect(screen.getByPlaceholderText('Custom search placeholder')).toBeInTheDocument();
    });

    it('does not show dropdown when there are no results', () => {
      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.queryByRole('button', { name: /john doe/i })).not.toBeInTheDocument();
    });
  });

  describe('Search functionality', () => {
    it('calls setQuery when typing in search input', async () => {
      const user = userEvent.setup();
      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      const input = screen.getByPlaceholderText(/search leads, deals, contacts/i);
      await user.type(input, 'john');

      await waitFor(() => {
        expect(mockSetQuery).toHaveBeenCalledWith('j');
        expect(mockSetQuery).toHaveBeenCalledWith('o');
        expect(mockSetQuery).toHaveBeenCalledWith('h');
        expect(mockSetQuery).toHaveBeenCalledWith('n');
      });
    });

    it('shows loading spinner when searching', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'john',
        setQuery: mockSetQuery,
        results: {
          leads: [],
          deals: [],
          contacts: [],
          companies: [],
        },
        isSearching: true,
        totalResults: 0,
        hasResults: false,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByLabelText('Searching')).toBeInTheDocument();
    });

    it('shows results when search returns data', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'john',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Enterprise Deal')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('Tech Startup Inc')).toBeInTheDocument();
    });
  });

  describe('Results grouping', () => {
    it('groups results by entity type', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByText(/leads \(1\)/i)).toBeInTheDocument();
      expect(screen.getByText(/deals \(1\)/i)).toBeInTheDocument();
      expect(screen.getByText(/contacts \(1\)/i)).toBeInTheDocument();
      expect(screen.getByText(/companies \(1\)/i)).toBeInTheDocument();
    });

    it('shows total result count', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByText('4 results')).toBeInTheDocument();
    });
  });

  describe('Keyboard navigation', () => {
    it('closes dropdown on Escape key', async () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      const input = screen.getByPlaceholderText(/search leads, deals, contacts/i);
      fireEvent.keyDown(input, { key: 'Escape', code: 'Escape' });

      await waitFor(() => {
        expect(mockClear).toHaveBeenCalled();
      });
    });

    it('navigates results with arrow keys', async () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      // Wait for the dropdown to open (useEffect sets isOpen=true when hasResults=true)
      await waitFor(() => {
        expect(screen.getByText('John Doe')).toBeInTheDocument();
      });

      // First result should be selected initially (selectedIndex=0)
      const firstResult = screen.getByText('John Doe').closest('button');
      expect(firstResult).toHaveClass('search-result-item--selected');

      const input = screen.getByPlaceholderText(/search leads, deals, contacts/i);

      // Arrow down should move selection to second result
      fireEvent.keyDown(input, { key: 'ArrowDown', code: 'ArrowDown' });

      await waitFor(() => {
        const secondResult = screen.getByText('Enterprise Deal').closest('button');
        expect(secondResult).toHaveClass('search-result-item--selected');
      });
    });

    it('shows keyboard hints when dropdown is open', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByText(/to navigate/i)).toBeInTheDocument();
      expect(screen.getByText(/to select/i)).toBeInTheDocument();
      expect(screen.getByText(/to close/i)).toBeInTheDocument();
    });
  });

  describe('Clear functionality', () => {
    it('shows clear button when query is not empty', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByLabelText('Clear search')).toBeInTheDocument();
    });

    it('calls clear when clear button is clicked', async () => {
      const user = userEvent.setup();
      mockUseGlobalSearch.mockReturnValue({
        query: 'test',
        setQuery: mockSetQuery,
        results: mockResults,
        isSearching: false,
        totalResults: 4,
        hasResults: true,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      const clearButton = screen.getByLabelText('Clear search');
      await user.click(clearButton);

      expect(mockClear).toHaveBeenCalled();
    });
  });

  describe('Empty state', () => {
    it('shows "no results" message when search returns empty', () => {
      mockUseGlobalSearch.mockReturnValue({
        query: 'nonexistent',
        setQuery: mockSetQuery,
        results: {
          leads: [],
          deals: [],
          contacts: [],
          companies: [],
        },
        isSearching: false,
        totalResults: 0,
        hasResults: false,
        clear: mockClear,
      });

      render(
        <TestWrapper>
          <GlobalSearch />
        </TestWrapper>
      );

      expect(screen.getByText(/no results found/i)).toBeInTheDocument();
    });
  });
});

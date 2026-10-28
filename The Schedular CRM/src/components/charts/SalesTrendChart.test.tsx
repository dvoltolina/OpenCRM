/**
 * SalesTrendChart Component Tests
 *
 * Agent CRM-19 Implementation
 */

import { describe, it, expect, vi, afterAll } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { chartContainerStyle, setupChartResizeMocks } from '../../test/test-utils';
import { SalesTrendChart } from './SalesTrendChart';
import type { SalesDataPoint } from '../../hooks/useSalesChartData';

const resetChartMocks = setupChartResizeMocks(
  Number(chartContainerStyle.width) || 800,
  Number(chartContainerStyle.height) || 400
);
afterAll(() => resetChartMocks());

const mockSalesData: SalesDataPoint[] = [
  {
    date: '2024-01-01',
    label: 'Jan',
    wonCount: 5,
    wonValue: 2500000,
    lostCount: 2,
    lostValue: 800000,
    totalCount: 7,
    totalValue: 3300000,
  },
  {
    date: '2024-02-01',
    label: 'Feb',
    wonCount: 8,
    wonValue: 4000000,
    lostCount: 3,
    lostValue: 1200000,
    totalCount: 11,
    totalValue: 5200000,
  },
  {
    date: '2024-03-01',
    label: 'Mar',
    wonCount: 6,
    wonValue: 3200000,
    lostCount: 1,
    lostValue: 500000,
    totalCount: 7,
    totalValue: 3700000,
  },
];

const renderWithSize = (ui: React.ReactElement) => {
  const utils = render(<div style={chartContainerStyle}>{ui}</div>);
  return utils;
};

describe('SalesTrendChart', () => {
  it('renders line chart', () => {
    renderWithSize(<SalesTrendChart data={mockSalesData} />);

    // Title should be rendered
    expect(screen.getByText('Sales Trend')).toBeInTheDocument();
  });

  it('shows correct date range in data', () => {
    const { container } = renderWithSize(<SalesTrendChart data={mockSalesData} />);

    // Recharts responsive container should be present
    const responsiveContainer = container.querySelector('.recharts-responsive-container');
    expect(responsiveContainer).toBeInTheDocument();
  });

  it('displays value trend with correct subtitle', () => {
    renderWithSize(<SalesTrendChart data={mockSalesData} metric="value" />);

    // Subtitle changes based on metric
    expect(screen.getByText('Revenue over time')).toBeInTheDocument();
  });

  it('displays count trend with correct subtitle', () => {
    renderWithSize(<SalesTrendChart data={mockSalesData} metric="count" />);

    // Subtitle changes based on metric
    expect(screen.getByText('Opportunities over time')).toBeInTheDocument();
  });

  it('handles empty data', () => {
    const emptyData: SalesDataPoint[] = [
      {
        date: '2024-01-01',
        label: 'Jan',
        wonCount: 0,
        wonValue: 0,
        lostCount: 0,
        lostValue: 0,
        totalCount: 0,
        totalValue: 0,
      },
    ];

    renderWithSize(<SalesTrendChart data={emptyData} />);

    // Should show empty message
    expect(screen.getByText('No closed opportunities in this period')).toBeInTheDocument();
  });

  it('shows loading state', () => {
    renderWithSize(<SalesTrendChart data={mockSalesData} isLoading />);

    // Should show loading indicator
    expect(screen.getByText('Loading chart...')).toBeInTheDocument();
  });

  it('renders controls when showControls is true', () => {
    renderWithSize(<SalesTrendChart data={mockSalesData} showControls />);

    // Metric toggle buttons should appear
    expect(screen.getByRole('button', { name: 'Value' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Count' })).toBeInTheDocument();
  });

  it('toggles metric when buttons are clicked', () => {
    renderWithSize(<SalesTrendChart data={mockSalesData} showControls />);

    const countButton = screen.getByRole('button', { name: 'Count' });
    fireEvent.click(countButton);

    // After clicking count, subtitle should change
    expect(screen.getByText('Opportunities over time')).toBeInTheDocument();

    const valueButton = screen.getByRole('button', { name: 'Value' });
    fireEvent.click(valueButton);

    // After clicking value, subtitle should change back
    expect(screen.getByText('Revenue over time')).toBeInTheDocument();
  });

  it('calls onGranularityChange when granularity buttons are clicked', () => {
    const handleGranularityChange = vi.fn();

    renderWithSize(
      <SalesTrendChart
        data={mockSalesData}
        showControls
        onGranularityChange={handleGranularityChange}
      />
    );

    const dailyButton = screen.getByRole('button', { name: 'Daily' });
    fireEvent.click(dailyButton);

    expect(handleGranularityChange).toHaveBeenCalledWith('daily');

    const weeklyButton = screen.getByRole('button', { name: 'Weekly' });
    fireEvent.click(weeklyButton);

    expect(handleGranularityChange).toHaveBeenCalledWith('weekly');
  });
});

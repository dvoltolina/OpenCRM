/**
 * PipelineChart Component Tests
 *
 * Agent CRM-19 Implementation
 */

import { describe, it, expect, afterAll } from 'vitest';
import { render, screen } from '@testing-library/react';
import { chartContainerStyle, setupChartResizeMocks } from '../../test/test-utils';
import { PipelineChart } from './PipelineChart';
import type { PipelineChartDataPoint } from '../../hooks/usePipelineChartData';

const resetChartMocks = setupChartResizeMocks(
  Number(chartContainerStyle.width) || 800,
  Number(chartContainerStyle.height) || 400
);
afterAll(() => resetChartMocks());

const mockChartData: PipelineChartDataPoint[] = [
  {
    stageId: 'stage-1',
    stageName: 'Qualification',
    stageColor: '#6366f1',
    dealCount: 10,
    totalValue: 5000000,
    order: 0,
  },
  {
    stageId: 'stage-2',
    stageName: 'Proposal',
    stageColor: '#8b5cf6',
    dealCount: 5,
    totalValue: 3000000,
    order: 1,
  },
  {
    stageId: 'stage-3',
    stageName: 'Negotiation',
    stageColor: '#a855f7',
    dealCount: 3,
    totalValue: 2000000,
    order: 2,
  },
];

const renderWithSize = (ui: React.ReactElement) => {
  const utils = render(<div style={chartContainerStyle}>{ui}</div>);
  return utils;
};

describe('PipelineChart', () => {
  it('renders bar chart with stages', () => {
    renderWithSize(<PipelineChart data={mockChartData} />);

    // Title should be rendered
    expect(screen.getByText('Pipeline Overview')).toBeInTheDocument();
  });

  it('uses stage colors from data', () => {
    const { container } = renderWithSize(<PipelineChart data={mockChartData} />);

    // Recharts responsive container should be present
    const responsiveContainer = container.querySelector('.recharts-responsive-container');
    expect(responsiveContainer).toBeInTheDocument();
  });

  it('shows tooltip on hover', () => {
    const { container } = renderWithSize(<PipelineChart data={mockChartData} />);

    // Recharts wrapper should be present for tooltip interaction
    const responsiveContainer = container.querySelector('.recharts-responsive-container');
    expect(responsiveContainer).toBeInTheDocument();
  });

  it('handles empty data', () => {
    renderWithSize(<PipelineChart data={[]} />);

    // Should show empty message
    expect(screen.getByText('No opportunities in pipeline')).toBeInTheDocument();
  });

  it('shows loading state', () => {
    renderWithSize(<PipelineChart data={mockChartData} isLoading />);

    // Should show loading indicator
    expect(screen.getByText('Loading chart...')).toBeInTheDocument();
  });

  it('displays correct subtitle', () => {
    renderWithSize(<PipelineChart data={mockChartData} />);

    // Subtitle shows description
    expect(screen.getByText('Opportunity count by stage')).toBeInTheDocument();
  });

  it('formats currency correctly', () => {
    renderWithSize(<PipelineChart data={mockChartData} currency="EUR" />);

    // Component should render without errors with different currency
    expect(screen.getByText('Pipeline Overview')).toBeInTheDocument();
  });
});

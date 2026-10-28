import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { ReportBuilder } from '../ReportBuilder';

describe('ReportBuilder', () => {
  it('blocks moving past basics when the report name is missing', () => {
    render(<ReportBuilder onSave={vi.fn()} onCancel={vi.fn()} />);

    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));

    expect(screen.getByText('Report name is required')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Name the report and choose its source' })).toBeInTheDocument();
  });

  it('saves a configured report definition', async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);

    render(<ReportBuilder onSave={onSave} onCancel={vi.fn()} />);

    fireEvent.change(screen.getByPlaceholderText('Monthly revenue by stage'), {
      target: { value: 'Revenue Pulse' },
    });

    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));

    const metricCard = screen.getByText('Value').closest('button');
    expect(metricCard).not.toBeNull();
    fireEvent.click(metricCard!);

    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    fireEvent.click(screen.getByTestId('report-builder-save'));

    await waitFor(() => {
      expect(onSave).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Revenue Pulse',
          reportType: 'deals',
          chartType: 'bar',
          dataSource: 'deals',
          defaultDateRange: 'this_month',
          metrics: [expect.objectContaining({ field: 'valueCents' })],
        })
      );
    });
  });
});

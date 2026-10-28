import { beforeEach, describe, expect, it, vi } from 'vitest';

import { fetchReports, requestReportExport } from './reports';
import { postTenantEndpoint } from './firestoreBase';

vi.mock('../config/demo', () => ({
  assertDemoMutationAllowed: vi.fn(),
}));

vi.mock('./firestoreBase', () => ({
  postTenantEndpoint: vi.fn(),
}));

const mockPostTenantEndpoint = vi.mocked(postTenantEndpoint);

describe('reports transport alignment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('loads live metrics from the shared reporting HTTP endpoint', async () => {
    mockPostTenantEndpoint.mockResolvedValue({
      success: true,
      metrics: {
        totalAppointments: 10,
        completedAppointments: 7,
        cancelledAppointments: 2,
        totalRevenue: 900,
        newClients: 3,
        averageRevenuePerAppointment: 90,
        completionRate: 70,
      },
    });

    const result = await fetchReports('biz_123', {
      startDate: '2026-03-01',
      endDate: '2026-03-22',
      granularity: 'day',
    });

    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/getReportMetrics', 'biz_123', {
      startDate: '2026-03-01',
      endDate: '2026-03-22',
      granularity: 'day',
    });
    expect(result.totalAppointments).toBe(10);
    expect(result.totalRevenue).toBe(900);
  });

  it('exports the selected dataset through the shared CSV endpoint', async () => {
    mockPostTenantEndpoint.mockResolvedValue('id,date\n1,2026-03-22');

    const result = await requestReportExport(
      'biz_123',
      'csv',
      'appointments',
      {
        startDate: '2026-03-01',
        endDate: '2026-03-22',
        granularity: 'day',
      },
    );

    expect(mockPostTenantEndpoint).toHaveBeenCalledWith('/exportReportCsv', 'biz_123', {
      reportType: 'appointments',
      startDate: '2026-03-01',
      endDate: '2026-03-22',
    });
    expect(result).toEqual(
      expect.objectContaining({
        mimeType: 'text/csv',
        fileName: 'reports-appointments-2026-03-01-2026-03-22.csv',
      }),
    );
  });
});

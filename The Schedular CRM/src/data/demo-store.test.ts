import { describe, expect, it } from 'vitest';

import { getLocalDemoCollection, getLocalDemoDocument } from './demo-store';

describe('demo store', () => {
  it('serves seeded demo business collections with basic filters', () => {
    const result = getLocalDemoCollection(
      'demo-business-001',
      'pipelines',
      {
        where: [{ field: 'isDefault', operator: '==', value: true }],
      }
    );

    expect(result.data).toHaveLength(1);
    expect(result.data[0].id).toBe('pipeline-demo-sales');
  });

  it('returns null for missing demo documents', () => {
    expect(
      getLocalDemoDocument('demo-business-001', 'pipelines', 'missing')
    ).toBeNull();
  });
});

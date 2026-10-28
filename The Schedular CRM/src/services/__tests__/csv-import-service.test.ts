import { describe, expect, it, vi } from 'vitest';
import {
  autoDetectMapping,
  importRows,
  validateAllRows,
  autoDetectMappingWithConfidence,
  type ImportConfig,
} from '../csv-import-service';

describe('csv-import-service', () => {
  const baseConfig: ImportConfig = {
    entityType: 'lead',
    fieldMapping: {
      firstName: 'firstName',
      lastName: 'lastName',
      email: 'email',
      phone: 'phone',
    },
    skipFirstRow: false,
    duplicateHandling: 'skip',
  };
  const headers = ['firstName', 'lastName', 'email', 'phone'];

  it('detects duplicate emails across rows', () => {
    const errors = validateAllRows(
      [
        ['Alice', 'Smith', 'first@example.com', '5551112222'],
        ['Bob', 'Jones', 'first@example.com', '5553334444'],
      ],
      headers,
      'lead',
      baseConfig.fieldMapping
    );

    expect(errors.some((err) => err.field === 'email' && err.row === 2)).toBe(true);
  });

  it('detects duplicate phones across rows', () => {
    const errors = validateAllRows(
      [
        ['Alice', 'Smith', 'person1@example.com', '(555) 123-4567'],
        ['Bob', 'Jones', 'person2@example.com', '5551234567'],
      ],
      headers,
      'contact',
      baseConfig.fieldMapping
    );

    expect(errors.some((err) => err.field === 'phone')).toBe(true);
  });

  it('rejects invalid phone format', () => {
    const errors = validateAllRows(
      [['Alice', 'Smith', 'person@example.com', 'abc123']],
      headers,
      'contact',
      baseConfig.fieldMapping
    );

    expect(errors.some((err) => err.field === 'phone')).toBe(true);
  });

  it('rejects short phone numbers after normalization', () => {
    const errors = validateAllRows(
      [['Alice', 'Smith', 'person@example.com', '123-45']],
      headers,
      'contact',
      baseConfig.fieldMapping
    );

    expect(errors.some((err) => err.field === 'phone' && err.error.includes('at least'))).toBe(true);
  });

  it('blocks rows that collide with existing identifiers', () => {
    const errors = validateAllRows(
      [['Alice', 'Smith', 'first@example.com', '+1 (555) 123-4567']],
      headers,
      'lead',
      baseConfig.fieldMapping,
      { emails: ['first@example.com'], phones: ['+15551234567'] }
    );

    expect(errors.some((err) => err.field === 'email')).toBe(true);
    expect(errors.some((err) => err.field === 'phone')).toBe(true);
  });

  it('matches phone collisions even when existing numbers omit the + prefix', () => {
    const errors = validateAllRows(
      [['Alice', 'Smith', 'another@example.com', '+1 (555) 123-4567']],
      headers,
      'contact',
      baseConfig.fieldMapping,
      { emails: [], phones: ['15551234567'] }
    );

    expect(errors.some((err) => err.field === 'phone')).toBe(true);
  });

  it('stops import when validation errors exist by default', async () => {
    const createEntity = vi.fn();

    const result = await importRows(
      [['Alice', 'Smith', 'not-an-email']],
      ['firstName', 'lastName', 'email'],
      {
        ...baseConfig,
        fieldMapping: { firstName: 'firstName', lastName: 'lastName', email: 'email' },
      },
      'biz-1',
      [],
      undefined,
      createEntity
    );

    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(1);
    expect(result.errors.length).toBeGreaterThan(0);
    expect(createEntity).not.toHaveBeenCalled();
  });

  it('returns dry-run results without writing data', async () => {
    const createEntity = vi.fn();

    const result = await importRows(
      [['Alice', 'Smith', 'valid@example.com', '555-999-1234']],
      headers,
      { ...baseConfig, dryRun: true },
      'biz-1',
      [],
      undefined,
      createEntity
    );

    expect(result.dryRun).toBe(true);
    expect(result.imported).toBe(0);
    expect(result.skipped).toBe(1);
    expect(result.errors).toHaveLength(0);
    expect(createEntity).not.toHaveBeenCalled();
  });

  it('maps address components into nested contact address object', async () => {
    const createEntity = vi.fn();

    await importRows(
      [['Alice', 'Smith', 'person@example.com', '123 Main St', 'Grand Junction', 'CO', '81501']],
      ['firstName', 'lastName', 'email', 'address', 'city', 'state', 'zipCode'],
      {
        entityType: 'contact',
        fieldMapping: {
          firstName: 'firstName',
          lastName: 'lastName',
          email: 'email',
          address: 'address',
          city: 'city',
          state: 'state',
          zipCode: 'zipCode',
        },
        skipFirstRow: false,
        duplicateHandling: 'create',
      },
      'biz-1',
      [],
      undefined,
      createEntity
    );

    expect(createEntity).toHaveBeenCalledTimes(1);
    const payload = createEntity.mock.calls[0][0];
    expect(payload.address).toEqual({
      street: '123 Main St',
      city: 'Grand Junction',
      state: 'CO',
      zipCode: '81501',
    });
  });

  it('requires a contact or company link for deals', () => {
    const errors = validateAllRows(
      [['Opportunity Only']],
      ['title'],
      'deal',
      { title: 'title' }
    );

    expect(errors.some((err) => err.field === 'clientEmail')).toBe(true);
  });

  it('accepts deals when a contact email is provided', () => {
    const errors = validateAllRows(
      [['Opportunity With Contact', 'person@example.com']],
      ['title', 'clientEmail'],
      'deal',
      { title: 'title', clientEmail: 'clientEmail' }
    );

    expect(errors.length).toBe(0);
  });

  it('maps a single "name" column to full-name split (first + last)', () => {
    const detection = autoDetectMappingWithConfidence(['name', 'email'], 'contact');
    expect(detection.hasFullName).toBe(true);
    expect(detection.mappings.name.field).toBe('firstName');
    expect(detection.mappings.name.needsTransform).toBe('splitName');
    expect(detection.overallConfidence).toBe(1);
  });

  it('auto-detects clientEmail headers for deal imports', () => {
    const mapping = autoDetectMapping(['title', 'clientEmail', 'clientName'], 'deal');

    expect(mapping.title).toBe('title');
    expect(mapping.clientEmail).toBe('clientEmail');
    expect(mapping.clientName).toBe('clientName');
  });
});

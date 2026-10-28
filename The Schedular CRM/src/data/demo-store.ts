import { buildDemoDocuments } from '../../scripts/demo-data/build-documents';
import { usesLocalDemoData } from '../config/demo';
import type { QueryOptions, WhereClause } from './repositories/repository-types';

type DemoDocument = {
  path: string;
  data: Record<string, unknown>;
  collection: string;
};

let demoDocuments: DemoDocument[] | null = null;

export function isLocalDemoDataEnabled(): boolean {
  return usesLocalDemoData;
}

function getDemoDocuments(): DemoDocument[] {
  if (!demoDocuments) {
    demoDocuments = buildDemoDocuments();
  }
  return demoDocuments;
}

function cloneRecord<T>(value: T): T {
  if (typeof structuredClone === 'function') {
    return structuredClone(value);
  }
  return value;
}

function collectionPrefix(businessId: string, collectionName: string): string {
  return `businesses/${businessId}/${collectionName}/`;
}

function readField(data: Record<string, unknown>, field: string): unknown {
  return field.split('.').reduce<unknown>((current, part) => {
    if (!current || typeof current !== 'object') {
      return undefined;
    }
    return (current as Record<string, unknown>)[part];
  }, data);
}

function toComparable(value: unknown): unknown {
  if (value instanceof Date) {
    return value.getTime();
  }
  if (
    value &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate: unknown }).toDate === 'function'
  ) {
    return (value as { toDate: () => Date }).toDate().getTime();
  }
  return value;
}

function matchesWhere(data: Record<string, unknown>, clause: WhereClause): boolean {
  const value = readField(data, clause.field);
  const expected = clause.value;

  switch (clause.operator) {
    case '==':
      return value === expected;
    case '!=':
      return value !== expected;
    case '<':
      return Number(toComparable(value)) < Number(toComparable(expected));
    case '<=':
      return Number(toComparable(value)) <= Number(toComparable(expected));
    case '>':
      return Number(toComparable(value)) > Number(toComparable(expected));
    case '>=':
      return Number(toComparable(value)) >= Number(toComparable(expected));
    case 'array-contains':
      return Array.isArray(value) && value.includes(expected);
    case 'array-contains-any':
      return Array.isArray(value) && Array.isArray(expected) && value.some((item) => expected.includes(item));
    case 'in':
      return Array.isArray(expected) && expected.includes(value);
    case 'not-in':
      return Array.isArray(expected) && !expected.includes(value);
    default:
      return true;
  }
}

function compareValues(a: unknown, b: unknown): number {
  const left = toComparable(a);
  const right = toComparable(b);

  if (left === right) return 0;
  if (left === undefined || left === null) return 1;
  if (right === undefined || right === null) return -1;

  if (typeof left === 'string' && typeof right === 'string') {
    return left.localeCompare(right);
  }

  return Number(left) < Number(right) ? -1 : 1;
}

function applyQueryOptions<T extends { id: string }>(
  records: T[],
  options: QueryOptions = {}
): T[] {
  let next = records;

  if (options.where?.length) {
    next = next.filter((record) =>
      options.where!.every((clause) => matchesWhere(record as Record<string, unknown>, clause))
    );
  }

  const orderClauses = [
    ...(options.orderBy ? [options.orderBy] : []),
    ...(options.orderByMultiple || []),
  ];
  if (orderClauses.length) {
    next = [...next].sort((a, b) => {
      for (const clause of orderClauses) {
        const comparison = compareValues(
          readField(a as Record<string, unknown>, clause.field),
          readField(b as Record<string, unknown>, clause.field)
        );
        if (comparison !== 0) {
          return clause.direction === 'desc' ? comparison * -1 : comparison;
        }
      }
      return 0;
    });
  }

  return next;
}

export function getLocalDemoCollection<T extends { id: string }>(
  businessId: string,
  collectionName: string,
  options: QueryOptions = {}
): { data: T[]; hasMore: boolean } {
  const prefix = collectionPrefix(businessId, collectionName);
  const records = getDemoDocuments()
    .filter((document) => document.path.startsWith(prefix))
    .map((document) => cloneRecord({ ...document.data, id: document.path.split('/').pop() || '' }) as T);

  const queried = applyQueryOptions(records, options);
  const limited = options.limit && options.limit > 0 ? queried.slice(0, options.limit) : queried;

  return {
    data: limited,
    hasMore: Boolean(options.limit && queried.length > options.limit),
  };
}

export function getLocalDemoDocument<T extends { id: string }>(
  businessId: string,
  collectionName: string,
  id: string
): T | null {
  const path = `${collectionPrefix(businessId, collectionName)}${id}`;
  const document = getDemoDocuments().find((entry) => entry.path === path);
  if (!document) {
    return null;
  }
  return cloneRecord({ ...document.data, id }) as T;
}

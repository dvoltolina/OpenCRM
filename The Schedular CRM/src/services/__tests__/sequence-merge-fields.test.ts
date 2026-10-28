/**
 * Merge Field Processor Tests
 *
 * Tests merge field processing for sequence templates
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  MergeFieldProcessor,
  getMergeFieldProcessor,
  getValidMergeFieldKeys,
  buildContextFromLead,
  buildContextFromClient,
  type MergeFieldContext,
} from '../sequence-merge-fields';

describe('MergeFieldProcessor', () => {
  let processor: MergeFieldProcessor;

  beforeEach(() => {
    processor = new MergeFieldProcessor();
  });

  describe('process', () => {
    const sampleContext: MergeFieldContext = {
      contact: {
        firstName: 'John',
        lastName: 'Smith',
        email: 'john@example.com',
        phone: '(555) 123-4567',
        title: 'CEO',
      },
      company: {
        name: 'Acme Corp',
        industry: 'Technology',
        website: 'www.acme.com',
      },
      sender: {
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '(555) 987-6543',
      },
      business: {
        name: 'My Business',
        phone: '(555) 000-0000',
        website: 'www.mybusiness.com',
        address: '123 Main St',
      },
      custom: {
        customField1: 'Custom Value',
      },
    };

    it('should replace firstName merge field', async () => {
      const result = await processor.process('Hello {{firstName}}!', sampleContext);
      expect(result).toBe('Hello John!');
    });

    it('should replace multiple merge fields', async () => {
      const template = 'Hi {{firstName}} {{lastName}}, welcome to {{companyName}}!';
      const result = await processor.process(template, sampleContext);
      expect(result).toBe('Hi John Smith, welcome to Acme Corp!');
    });

    it('should replace fullName merge field', async () => {
      const result = await processor.process('Dear {{fullName}},', sampleContext);
      expect(result).toBe('Dear John Smith,');
    });

    it('should replace sender fields', async () => {
      const template = 'Best regards,\n{{senderName}}\n{{senderEmail}}';
      const result = await processor.process(template, sampleContext);
      expect(result).toBe('Best regards,\nJane Doe\njane@example.com');
    });

    it('should replace business fields', async () => {
      const template = 'Contact us at {{businessPhone}} or visit {{businessWebsite}}';
      const result = await processor.process(template, sampleContext);
      expect(result).toBe('Contact us at (555) 000-0000 or visit www.mybusiness.com');
    });

    it('should handle missing values gracefully', async () => {
      const context: MergeFieldContext = {
        contact: { email: 'test@test.com' },
        company: {},
        sender: { name: 'Sender', email: 'sender@test.com' },
        business: { name: 'Business' },
        custom: {},
      };
      const result = await processor.process('Hello {{firstName}} {{lastName}}!', context);
      expect(result).toBe('Hello  !'); // Empty strings for missing values
    });

    it('should replace custom fields', async () => {
      const result = await processor.process('Value: {{customField1}}', sampleContext);
      expect(result).toBe('Value: Custom Value');
    });
  });

  describe('processSync', () => {
    it('should process synchronously', () => {
      const context: MergeFieldContext = {
        contact: { firstName: 'Test', email: 'test@test.com' },
        company: {},
        sender: { name: 'Sender', email: 'sender@test.com' },
        business: { name: 'Business' },
        custom: {},
      };
      const result = processor.processSync('Hello {{firstName}}!', context);
      expect(result).toBe('Hello Test!');
    });
  });

  describe('extractFields', () => {
    it('should extract all merge fields from template', () => {
      const template = 'Hi {{firstName}} {{lastName}}, from {{companyName}}. Contact {{senderName}}.';
      const fields = processor.extractFields(template);

      expect(fields).toContain('firstName');
      expect(fields).toContain('lastName');
      expect(fields).toContain('companyName');
      expect(fields).toContain('senderName');
      expect(fields).toHaveLength(4);
    });

    it('should not return duplicate fields', () => {
      const template = '{{firstName}} {{firstName}} {{firstName}}';
      const fields = processor.extractFields(template);
      expect(fields).toHaveLength(1);
      expect(fields[0]).toBe('firstName');
    });

    it('should return empty array for template without fields', () => {
      const fields = processor.extractFields('Hello world!');
      expect(fields).toHaveLength(0);
    });
  });

  describe('validate', () => {
    it('should validate template with valid fields', () => {
      const template = 'Hello {{firstName}} {{lastName}}!';
      const result = processor.validate(template);
      expect(result.valid).toBe(true);
      expect(result.unknownFields).toHaveLength(0);
    });

    it('should detect unknown fields', () => {
      const template = 'Hello {{unknownField}}!';
      const result = processor.validate(template);
      expect(result.valid).toBe(false);
      expect(result.unknownFields).toContain('unknownField');
    });

    it('should allow custom_ prefixed fields', () => {
      const template = 'Value: {{custom_myField}}';
      const result = processor.validate(template);
      expect(result.valid).toBe(true);
    });

    it('should warn about unclosed brackets', () => {
      const template = 'Hello {{firstName';
      const result = processor.validate(template);
      expect(result.warnings).toBeDefined();
      expect(result.warnings).toContain('Template contains unclosed merge field brackets');
    });
  });

  describe('preview', () => {
    it('should replace fields with sample data', () => {
      const template = 'Hello {{firstName}} from {{companyName}}!';
      const result = processor.preview(template);

      expect(result).toContain('John'); // Sample first name
      expect(result).toContain('Acme Corporation'); // Sample company name
    });
  });

  describe('getFieldsByCategory', () => {
    it('should group fields by category', () => {
      const grouped = processor.getFieldsByCategory();

      expect(grouped.contact).toBeDefined();
      expect(grouped.company).toBeDefined();
      expect(grouped.sender).toBeDefined();
      expect(grouped.business).toBeDefined();

      expect(grouped.contact.some((f) => f.key === 'firstName')).toBe(true);
      expect(grouped.company.some((f) => f.key === 'companyName')).toBe(true);
      expect(grouped.sender.some((f) => f.key === 'senderName')).toBe(true);
      expect(grouped.business.some((f) => f.key === 'businessName')).toBe(true);
    });
  });
});

describe('getValidMergeFieldKeys', () => {
  it('should return array of valid field keys', () => {
    const keys = getValidMergeFieldKeys();
    expect(Array.isArray(keys)).toBe(true);
    expect(keys).toContain('firstName');
    expect(keys).toContain('lastName');
    expect(keys).toContain('email');
    expect(keys).toContain('companyName');
    expect(keys).toContain('senderName');
    expect(keys).toContain('businessName');
  });
});

describe('buildContextFromLead', () => {
  it('should build context from lead data', () => {
    const lead = {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: '555-1234',
      title: 'Manager',
      companyName: 'Acme',
    };
    const sender = { name: 'Jane', email: 'jane@example.com' };
    const business = { name: 'My Business' };

    const context = buildContextFromLead(lead, sender, business);

    expect(context.contact.firstName).toBe('John');
    expect(context.contact.lastName).toBe('Doe');
    expect(context.contact.email).toBe('john@example.com');
    expect(context.company.name).toBe('Acme');
    expect(context.sender.name).toBe('Jane');
    expect(context.business.name).toBe('My Business');
  });
});

describe('buildContextFromClient', () => {
  it('should build context from client data', () => {
    const client = {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
    };
    const company = { name: 'Client Company', industry: 'Tech' };
    const sender = { name: 'Jane', email: 'jane@example.com' };
    const business = { name: 'My Business' };

    const context = buildContextFromClient(client, company, sender, business);

    expect(context.contact.firstName).toBe('John');
    expect(context.company.name).toBe('Client Company');
    expect(context.company.industry).toBe('Tech');
  });

  it('should use client companyName if company object is undefined', () => {
    const client = {
      firstName: 'John',
      email: 'john@example.com',
      companyName: 'Fallback Company',
    };
    const sender = { name: 'Jane', email: 'jane@example.com' };
    const business = { name: 'My Business' };

    const context = buildContextFromClient(client, undefined, sender, business);

    expect(context.company.name).toBe('Fallback Company');
  });
});

describe('getMergeFieldProcessor', () => {
  it('should return singleton instance', () => {
    const instance1 = getMergeFieldProcessor();
    const instance2 = getMergeFieldProcessor();
    expect(instance1).toBe(instance2);
  });
});

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { PaymentService, getPaymentService } from '../payment-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { ChargeClientRequest } from '../payment-service';
import type { Payment, PaymentMethodCard } from '../../types/models';

const mockPaymentRepo = {
  create: vi.fn(),
  getHistory: vi.fn(),
  getById: vi.fn(),
};

const mockPaymentMethodRepo = {
  createForClient: vi.fn(),
  getByClient: vi.fn(),
};

const mockDealGetById = vi.fn();

vi.mock('../../data/repositories/payment-repository', () => ({
  getPaymentRepository: () => mockPaymentRepo,
}));

vi.mock('../../data/repositories/payment-method-repository', () => ({
  getPaymentMethodRepository: () => mockPaymentMethodRepo,
}));

vi.mock('../../data/repositories/deal-repository', () => ({
  getDealRepository: () => ({
    getById: mockDealGetById,
  }),
}));

// ============================================
// Test Data
// ============================================

const mockContext: SecurityContext = {
  businessId: 'business-123',
  userId: 'user-123',
  userName: 'Test User',
  userRole: 'admin',
};

const buildMockPayment = (overrides: Partial<Payment> = {}): Payment => ({
  id: 'payment-123',
  amountCents: 5000,
  currency: 'USD',
  status: 'completed',
  method: 'card',
  type: 'full',
  description: 'Consultation',
  clientId: 'client-123',
  clientName: 'John Doe',
  dealId: 'deal-123',
  dealTitle: 'Consultation Deal',
  providerId: 'ch_123456',
  receiptUrl: 'https://receipts.example.com/ch_123456',
  last4: '4242',
  cardBrand: 'visa',
  processedById: 'user-123',
  processedByName: 'Test User',
  processedAt: new Date(),
  createdAt: new Date(),
  ...overrides,
});

const validChargeRequest: ChargeClientRequest = {
  amountCents: 10000,
  currency: 'USD',
  clientId: 'client-123',
  clientName: 'John Doe',
  dealId: 'deal-123',
  dealTitle: 'Big Deal',
  method: 'card',
  paymentMethodId: 'pm_123',
  description: 'Test payment',
};

// ============================================
// Tests
// ============================================

describe('PaymentService', () => {
  let service: PaymentService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new PaymentService();
    mockPaymentRepo.create.mockImplementation(async (_context, data) => ({
      success: true,
      data: buildMockPayment({ ...data }),
    }));
    mockPaymentRepo.getHistory.mockResolvedValue({
      success: true,
      data: { data: [buildMockPayment()] },
    });
    mockPaymentRepo.getById.mockResolvedValue({
      success: true,
      data: buildMockPayment(),
    });
    mockPaymentMethodRepo.createForClient.mockResolvedValue({
      success: true,
      data: {
        id: 'pm-123',
        providerId: 'pm_mock',
        last4: '4242',
        brand: 'visa',
        expMonth: 12,
        expYear: 2030,
        isDefault: false,
        createdAt: new Date(),
      } as PaymentMethodCard,
    });
    mockPaymentMethodRepo.getByClient.mockResolvedValue({
      success: true,
      data: [
        {
          id: 'pm-123',
          providerId: 'pm_stripe_123',
          last4: '4242',
          brand: 'visa',
          expMonth: 12,
          expYear: 2025,
          isDefault: true,
          createdAt: new Date(),
        },
      ],
    });
    mockDealGetById.mockResolvedValue({
      success: true,
      data: { id: 'deal-123', title: 'Big Deal', status: 'open' },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // ============================================
  // chargeClient Tests
  // ============================================

  describe('chargeClient', () => {
    it('should successfully charge a client with a saved card', async () => {
      const result = await service.chargeClient(mockContext, validChargeRequest);

      expect(result.success).toBe(true);
      expect(result.payment).toBeDefined();
      expect(result.payment?.amountCents).toBe(10000);
      expect(result.payment?.currency).toBe('USD');
      expect(result.payment?.clientId).toBe('client-123');
      expect(result.payment?.method).toBe('card');
      expect(result.payment?.status).toBe('completed');
      expect(mockPaymentRepo.create).toHaveBeenCalledTimes(1);
    });

    it('should successfully charge a client with a new card', async () => {
      const newCardRequest: ChargeClientRequest = {
        ...validChargeRequest,
        method: 'new_card',
        paymentMethodId: undefined,
        newCardToken: 'tok_new_card',
        saveCard: false,
      };

      const result = await service.chargeClient(mockContext, newCardRequest);

      expect(result.success).toBe(true);
      expect(result.payment?.method).toBe('card');
      expect(mockPaymentRepo.create).toHaveBeenCalledTimes(1);
    });

    it('should save card when saveCard is true', async () => {
      const saveCardRequest: ChargeClientRequest = {
        ...validChargeRequest,
        method: 'new_card',
        paymentMethodId: undefined,
        newCardToken: 'tok_new_card',
        saveCard: true,
      };

      const result = await service.chargeClient(mockContext, saveCardRequest);

      expect(result.success).toBe(true);
      expect(mockPaymentRepo.create).toHaveBeenCalledTimes(1);
      expect(mockPaymentMethodRepo.createForClient).toHaveBeenCalledTimes(1);
      expect(mockPaymentMethodRepo.createForClient).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        'client-123',
        expect.objectContaining({ providerId: expect.stringContaining('pm_mock_') })
      );
    });

    it('should successfully record a cash payment', async () => {
      const cashRequest: ChargeClientRequest = {
        ...validChargeRequest,
        method: 'cash',
        paymentMethodId: undefined,
      };

      const result = await service.chargeClient(mockContext, cashRequest);

      expect(result.success).toBe(true);
      expect(result.payment?.method).toBe('cash');
      expect(mockPaymentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.objectContaining({ method: 'cash' })
      );
    });

    it('should successfully record a check payment', async () => {
      const checkRequest: ChargeClientRequest = {
        ...validChargeRequest,
        method: 'check',
        paymentMethodId: undefined,
      };

      const result = await service.chargeClient(mockContext, checkRequest);

      expect(result.success).toBe(true);
      expect(result.payment?.method).toBe('check');
      expect(mockPaymentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.objectContaining({ method: 'check' })
      );
    });

    it('should link payment to deal when dealId is provided', async () => {
      const result = await service.chargeClient(mockContext, validChargeRequest);

      expect(result.success).toBe(true);
      expect(result.payment?.dealId).toBe('deal-123');
      expect(result.payment?.dealTitle).toBe('Big Deal');
    });

    it('should fail with invalid amount (zero)', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        amountCents: 0,
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Amount must be greater than 0');
      expect(mockPaymentRepo.create).not.toHaveBeenCalled();
    });

    it('should fail with negative amount', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        amountCents: -1000,
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Amount must be greater than 0');
    });

    it('should fail without currency', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        currency: '',
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Currency is required');
    });

    it('should fail without clientId', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        clientId: '',
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Client ID is required');
    });

    it('should fail without clientName', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        clientName: '',
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Client name is required');
    });

    it('should fail when card payment missing paymentMethodId', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        paymentMethodId: undefined,
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Payment method ID is required for card payments');
    });

    it('should fail when new_card missing token', async () => {
      const invalidRequest: ChargeClientRequest = {
        ...validChargeRequest,
        method: 'new_card',
        paymentMethodId: undefined,
        newCardToken: undefined,
      };

      const result = await service.chargeClient(mockContext, invalidRequest);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Card token is required for new card payments');
    });

    it('should scope payment to business', async () => {
      await service.chargeClient(mockContext, validChargeRequest);

      expect(mockPaymentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.any(Object)
      );
    });

    it('should record processor information', async () => {
      const result = await service.chargeClient(mockContext, validChargeRequest);

      expect(result.payment?.processedById).toBe('user-123');
      expect(result.payment?.processedByName).toBe('Test User');
      expect(result.payment?.processedAt).toBeInstanceOf(Date);
    });
  });

  // ============================================
  // getPaymentHistory Tests
  // ============================================

  describe('getPaymentHistory', () => {
    it('should fetch payment history for a client', async () => {
      mockPaymentRepo.getHistory.mockResolvedValue({
        success: true,
        data: { data: [buildMockPayment()] },
      });

      const result = await service.getPaymentHistory(mockContext, {
        clientId: 'client-123',
      });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('payment-123');
      expect(mockPaymentRepo.getHistory).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.objectContaining({ clientId: 'client-123', limit: 50 })
      );
    });

    it('should fetch payment history for a deal', async () => {
      mockPaymentRepo.getHistory.mockResolvedValue({
        success: true,
        data: { data: [buildMockPayment({ dealId: 'deal-123' })] },
      });

      const result = await service.getPaymentHistory(mockContext, {
        dealId: 'deal-123',
      });

      expect(result).toHaveLength(1);
      expect(mockPaymentRepo.getHistory).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.objectContaining({ dealId: 'deal-123', limit: 50 })
      );
    });

    it('should apply limit when specified', async () => {
      await service.getPaymentHistory(mockContext, {
        clientId: 'client-123',
        limit: 10,
      });

      expect(mockPaymentRepo.getHistory).toHaveBeenCalledWith(
        expect.any(Object),
        expect.objectContaining({ clientId: 'client-123', limit: 10 })
      );
    });

    it('should order by createdAt descending', async () => {
      await service.getPaymentHistory(mockContext, {
        clientId: 'client-123',
      });

      expect(mockPaymentRepo.getHistory).toHaveBeenCalledWith(
        expect.any(Object),
        expect.objectContaining({ clientId: 'client-123' })
      );
    });

    it('should return empty array on error', async () => {
      mockPaymentRepo.getHistory.mockResolvedValue({
        success: false,
        data: null,
        error: { code: 'error', message: 'Database error' },
      });

      const result = await service.getPaymentHistory(mockContext, {
        clientId: 'client-123',
      });

      expect(result).toEqual([]);
    });

    it('should scope query to business', async () => {
      await service.getPaymentHistory(mockContext, {
        clientId: 'client-123',
      });

      expect(mockPaymentRepo.getHistory).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        expect.any(Object)
      );
    });
  });

  // ============================================
  // getPaymentById Tests
  // ============================================

  describe('getPaymentById', () => {
    it('should fetch a payment by ID', async () => {
      mockPaymentRepo.getById.mockResolvedValue({
        success: true,
        data: buildMockPayment(),
      });

      const result = await service.getPaymentById(mockContext, 'payment-123');

      expect(result).not.toBeNull();
      expect(result?.id).toBe('payment-123');
      expect(mockPaymentRepo.getById).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        'payment-123'
      );
    });

    it('should return null when payment not found', async () => {
      mockPaymentRepo.getById.mockResolvedValue({
        success: false,
        data: null,
        error: { code: 'NOT_FOUND', message: 'Not found' },
      });

      const result = await service.getPaymentById(mockContext, 'nonexistent');

      expect(result).toBeNull();
    });

    it('should return null on error', async () => {
      mockPaymentRepo.getById.mockRejectedValue(new Error('Database error'));

      const result = await service.getPaymentById(mockContext, 'payment-123');

      expect(result).toBeNull();
    });

    it('should scope query to business', async () => {
      mockPaymentRepo.getById.mockResolvedValue({
        success: true,
        data: buildMockPayment(),
      });

      await service.getPaymentById(mockContext, 'payment-123');

      expect(mockPaymentRepo.getById).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        'payment-123'
      );
    });
  });

  // ============================================
  // getPaymentMethods Tests
  // ============================================

  describe('getPaymentMethods', () => {
    it('should fetch saved payment methods for a client', async () => {
      const result = await service.getPaymentMethods(mockContext, 'client-123');

      expect(result).toHaveLength(1);
      expect(result[0].last4).toBe('4242');
      expect(result[0].brand).toBe('visa');
      expect(mockPaymentMethodRepo.getByClient).toHaveBeenCalledWith(
        expect.objectContaining({ businessId: 'business-123' }),
        'client-123'
      );
    });

    it('should return empty array when no saved cards', async () => {
      mockPaymentMethodRepo.getByClient.mockResolvedValue({
        success: true,
        data: [],
      });

      const result = await service.getPaymentMethods(mockContext, 'client-123');

      expect(result).toEqual([]);
    });

    it('should return empty array on error', async () => {
      mockPaymentMethodRepo.getByClient.mockResolvedValue({
        success: false,
        data: null,
        error: { code: 'error', message: 'Database error' },
      });

      const result = await service.getPaymentMethods(mockContext, 'client-123');

      expect(result).toEqual([]);
    });
  });

  // ============================================
  // Singleton Tests
  // ============================================

  describe('getPaymentService', () => {
    it('should return singleton instance', () => {
      const instance1 = getPaymentService();
      const instance2 = getPaymentService();

      expect(instance1).toBe(instance2);
    });
  });
});

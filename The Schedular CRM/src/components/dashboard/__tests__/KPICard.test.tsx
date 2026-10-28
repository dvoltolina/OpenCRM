/**
 * KPICard Component Tests
 *
 * Agent CRM-18 Implementation
 */

import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { KPICard } from '../KPICard';

describe('KPICard', () => {
  // ============================================
  // Test 1: Displays title and value
  // ============================================
  it('displays title and value', () => {
    render(
      <KPICard
        title="Total Pipeline Value"
        value={150000}
        format="currency"
      />
    );

    expect(screen.getByText('Total Pipeline Value')).toBeInTheDocument();
    expect(screen.getByText('$1,500')).toBeInTheDocument(); // 150000 cents = $1,500
  });

  // ============================================
  // Test 2: Shows trend indicator
  // ============================================
  it('shows trend indicator', () => {
    render(
      <KPICard
        title="Deals Won"
        value={25}
        format="number"
        change={{ value: 15, period: 'vs last month' }}
        trend="up"
      />
    );

    expect(screen.getByText('Deals Won')).toBeInTheDocument();
    expect(screen.getByText('25')).toBeInTheDocument();
    expect(screen.getByText(/\+15%/)).toBeInTheDocument();
    expect(screen.getByText('vs last month')).toBeInTheDocument();

    // Check for up arrow
    const trendElement = screen.getByText(/\+15%/).closest('.kpi-card__trend');
    expect(trendElement).toHaveClass('kpi-card__trend--up');
  });

  // ============================================
  // Test 3: Formats currency correctly
  // ============================================
  it('formats currency correctly', () => {
    render(
      <KPICard
        title="Revenue"
        value={500000} // 500000 cents = $5,000
        format="currency"
      />
    );

    expect(screen.getByText('$5,000')).toBeInTheDocument();
  });

  // ============================================
  // Test 4: Formats percentage correctly
  // ============================================
  it('formats percentage correctly', () => {
    render(
      <KPICard
        title="Conversion Rate"
        value={45.5}
        format="percent"
      />
    );

    expect(screen.getByText('45.5%')).toBeInTheDocument();
  });

  // ============================================
  // Additional Tests
  // ============================================

  it('displays icon when provided', () => {
    render(
      <KPICard
        title="New Leads"
        value={10}
        format="number"
        icon={<span data-testid="lead-icon">👤</span>}
      />
    );

    expect(screen.getByTestId('lead-icon')).toBeInTheDocument();
  });

  it('handles string values', () => {
    render(
      <KPICard
        title="Status"
        value="Active"
      />
    );

    expect(screen.getByText('Active')).toBeInTheDocument();
  });

  it('shows down trend correctly', () => {
    render(
      <KPICard
        title="Lost Deals"
        value={5}
        format="number"
        change={{ value: -10, period: 'vs last week' }}
        trend="down"
      />
    );

    expect(screen.getByText(/-10%/)).toBeInTheDocument();
    const trendElement = screen.getByText(/-10%/).closest('.kpi-card__trend');
    expect(trendElement).toHaveClass('kpi-card__trend--down');
  });

  it('shows neutral trend correctly', () => {
    render(
      <KPICard
        title="Average"
        value={100}
        format="number"
        change={{ value: 0, period: 'no change' }}
        trend="neutral"
      />
    );

    const trendElement = screen.getByText(/0%/).closest('.kpi-card__trend');
    expect(trendElement).toHaveClass('kpi-card__trend--neutral');
  });

  it('formats large numbers with commas', () => {
    render(
      <KPICard
        title="Big Number"
        value={1234567}
        format="number"
      />
    );

    expect(screen.getByText('1,234,567')).toBeInTheDocument();
  });
});

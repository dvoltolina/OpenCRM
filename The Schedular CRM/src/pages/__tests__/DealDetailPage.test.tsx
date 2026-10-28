import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom';
import { DealDetailPage } from '../DealDetailPage';

vi.mock('../../components/details', () => ({
  DealDetail: ({
    onClientClick,
  }: {
    onClientClick?: (clientId: string) => void;
  }) => (
    <button type="button" onClick={() => onClientClick?.('client-123')}>
      Open Linked Contact
    </button>
  ),
}));

vi.mock('../../hooks', () => ({
  useDealMutations: () => ({
    markWon: vi.fn(),
    markLost: vi.fn(),
  }),
}));

function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location-path">{location.pathname}</div>;
}

describe('DealDetailPage', () => {
  it('navigates to the linked contact detail route', () => {
    render(
      <MemoryRouter initialEntries={['/deals/deal-1']}>
        <Routes>
          <Route
            path="/deals/:dealId"
            element={
              <>
                <LocationDisplay />
                <DealDetailPage />
              </>
            }
          />
          <Route
            path="/contacts/:contactId"
            element={<LocationDisplay />}
          />
        </Routes>
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Open Linked Contact' }));

    expect(screen.getByTestId('location-path')).toHaveTextContent('/contacts/client-123');
  });
});

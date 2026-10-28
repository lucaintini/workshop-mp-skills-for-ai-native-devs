import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { expect, it, vi } from 'vitest';
import { useAuth } from '../context/AuthContext';
import Header from './Header';

vi.mock('../context/AuthContext', () => ({ useAuth: vi.fn() }));

it('shows authenticated shoppers a Favourites navigation link', () => {
  useAuth.mockReturnValue({
    email: 'demouser@perthai.com.au',
    isAuthenticated: true,
    basketCount: 0,
    logout: vi.fn(),
  });

  render(
    <MemoryRouter>
      <Header />
    </MemoryRouter>,
  );

  expect(screen.getByRole('link', { name: 'Favourites' })).toHaveAttribute('href', '/favourites');
});

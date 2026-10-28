import { act, fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, expect, it, vi } from 'vitest';
import { SESSION_EXPIRED_EVENT, api } from '../api/client';
import { AuthProvider, useAuth } from './AuthContext';

vi.mock('../api/client', () => ({
  SESSION_EXPIRED_EVENT: 'eshop:session-expired',
  api: {
    getEmail: vi.fn(() => null),
    getToken: vi.fn(() => 'test-token'),
    getBasket: vi.fn(() => Promise.resolve({ item_count: 0 })),
    login: vi.fn((email) => Promise.resolve({ email, access_token: 'login-token' })),
    register: vi.fn((email) => Promise.resolve({ email, access_token: 'register-token' })),
    setAuth: vi.fn(),
    clearAuth: vi.fn(),
  },
}));

function SessionHarness() {
  const { login, logout, register, sessionVersion } = useAuth();
  return (
    <>
      <output>version:{sessionVersion}</output>
      <button type="button" onClick={() => login('alice@example.com', 'password')}>Login</button>
      <button type="button" onClick={logout}>Logout</button>
      <button type="button" onClick={() => register('bob@example.com', 'password')}>Register</button>
    </>
  );
}

beforeEach(() => {
  vi.clearAllMocks();
  api.getEmail.mockReturnValue(null);
  api.getToken.mockReturnValue('test-token');
  api.getBasket.mockResolvedValue({ item_count: 0 });
  window.history.replaceState({}, '', '/login');
});

it('advances the auth session generation for every invalidating transition', async () => {
  render(
    <AuthProvider>
      <SessionHarness />
    </AuthProvider>,
  );

  expect(screen.getByText('version:0')).toBeInTheDocument();

  fireEvent.click(screen.getByRole('button', { name: 'Login' }));
  expect(await screen.findByText('version:1')).toBeInTheDocument();

  fireEvent.click(screen.getByRole('button', { name: 'Logout' }));
  expect(screen.getByText('version:2')).toBeInTheDocument();

  fireEvent.click(screen.getByRole('button', { name: 'Login' }));
  expect(await screen.findByText('version:3')).toBeInTheDocument();

  fireEvent.click(screen.getByRole('button', { name: 'Register' }));
  expect(await screen.findByText('version:4')).toBeInTheDocument();

  act(() => window.dispatchEvent(new Event(SESSION_EXPIRED_EVENT)));
  expect(await screen.findByText('version:5')).toBeInTheDocument();
});

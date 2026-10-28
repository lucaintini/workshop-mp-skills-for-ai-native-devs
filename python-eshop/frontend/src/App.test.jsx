import { render, screen } from '@testing-library/react';
import { expect, it, vi } from 'vitest';
import App from './App';

vi.mock('./context/AuthContext', () => ({
  AuthProvider: ({ children }) => children,
  useAuth: () => ({
    email: 'demouser@perthai.com.au',
    isAuthenticated: true,
    basketCount: 0,
    logout: vi.fn(),
  }),
}));

vi.mock('./components/Layout', () => ({ default: ({ children }) => children }));
vi.mock('./pages/FavouritesPage', () => ({ default: () => <h1>Favourites route</h1> }));

it('routes /favourites to the Favourites page', () => {
  window.history.pushState({}, '', '/favourites');
  render(<App />);
  expect(screen.getByRole('heading', { name: 'Favourites route' })).toBeInTheDocument();
});

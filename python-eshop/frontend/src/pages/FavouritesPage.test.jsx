import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import FavouritesPage from './FavouritesPage';

vi.mock('../api/client', () => ({
  api: { getFavourites: vi.fn() },
}));

vi.mock('../context/AuthContext', () => ({ useAuth: vi.fn() }));

vi.mock('../components/ProductCard', () => ({
  default: ({ item, onFavouriteChange }) => (
    <article>
      <p>{item.name}</p>
      <button type="button" onClick={() => onFavouriteChange(item.id, false)}>
        Remove test favourite
      </button>
    </article>
  ),
}));

const item = { id: 1, name: '.NET Bot Black Sweatshirt' };

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/favourites']}>
      <Routes>
        <Route path="/favourites" element={<FavouritesPage />} />
        <Route path="/login" element={<p>Login page</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

describe('FavouritesPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('protects the collection behind login', async () => {
    useAuth.mockReturnValue({ isAuthenticated: false });
    renderPage();
    expect(await screen.findByText('Login page')).toBeInTheDocument();
    expect(api.getFavourites).not.toHaveBeenCalled();
  });

  it('shows an empty state that returns to the catalog', async () => {
    useAuth.mockReturnValue({ isAuthenticated: true });
    api.getFavourites.mockResolvedValue([]);
    renderPage();
    expect(await screen.findByText('No favourites yet')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Browse the catalog' })).toHaveAttribute('href', '/');
  });

  it('keeps the loading state visible while the collection request is pending', () => {
    useAuth.mockReturnValue({ isAuthenticated: true });
    api.getFavourites.mockReturnValue(new Promise(() => {}));
    renderPage();
    expect(screen.getByText('Loading favourites...')).toBeInTheDocument();
  });

  it('shows load errors instead of disguising them as an empty collection', async () => {
    useAuth.mockReturnValue({ isAuthenticated: true });
    api.getFavourites.mockRejectedValue(new Error('Could not load favourites'));
    renderPage();
    expect(await screen.findByRole('alert')).toHaveTextContent('Could not load favourites');
    expect(screen.queryByText('No favourites yet')).not.toBeInTheDocument();
  });

  it('lists favourites and removes a card after a successful toggle', async () => {
    useAuth.mockReturnValue({ isAuthenticated: true });
    api.getFavourites.mockResolvedValue([item]);
    renderPage();
    expect(await screen.findByText(item.name)).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Remove test favourite' }));
    await waitFor(() => expect(screen.queryByText(item.name)).not.toBeInTheDocument());
    expect(screen.getByText('No favourites yet')).toBeInTheDocument();
  });
});

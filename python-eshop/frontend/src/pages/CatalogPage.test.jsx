import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, expect, it, vi } from 'vitest';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import CatalogPage from './CatalogPage';

vi.mock('../api/client', () => ({
  api: {
    getBrands: vi.fn(),
    getTypes: vi.fn(),
    getCatalogItems: vi.fn(),
    getFavourites: vi.fn(),
  },
}));

vi.mock('../context/AuthContext', () => ({ useAuth: vi.fn() }));
vi.mock('../components/CatalogFilters', () => ({ default: () => null }));
vi.mock('../components/Pagination', () => ({ default: () => null }));
vi.mock('../components/ProductCard', () => ({
  default: ({ item, initialFavourite, onFavouriteChange }) => (
    <article>
      <p>{`${item.name}:${initialFavourite}`}</p>
      <button type="button" onClick={() => onFavouriteChange(item.id, !initialFavourite)}>
        Toggle test favourite
      </button>
    </article>
  ),
}));

const item = { id: 1, name: '.NET Bot Black Sweatshirt' };

beforeEach(() => {
  vi.clearAllMocks();
  useAuth.mockReturnValue({ isAuthenticated: true });
  api.getBrands.mockResolvedValue([]);
  api.getTypes.mockResolvedValue([]);
  api.getCatalogItems.mockResolvedValue({ items: [item], page: 1, total_pages: 1 });
  api.getFavourites.mockResolvedValue([item]);
});

it('loads saved Favourite state and keeps catalog cards synchronized after a toggle', async () => {
  render(
    <MemoryRouter>
      <CatalogPage />
    </MemoryRouter>,
  );

  expect(await screen.findByText(`${item.name}:true`)).toBeInTheDocument();
  fireEvent.click(screen.getByRole('button', { name: 'Toggle test favourite' }));
  expect(await screen.findByText(`${item.name}:false`)).toBeInTheDocument();
});

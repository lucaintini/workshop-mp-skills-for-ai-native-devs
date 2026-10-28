import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import ProductCard from './ProductCard';

vi.mock('../api/client', () => ({
  api: {
    addFavourite: vi.fn(),
    removeFavourite: vi.fn(),
    addToBasket: vi.fn(),
  },
}));

vi.mock('../context/AuthContext', () => ({ useAuth: vi.fn() }));

const item = {
  id: 1,
  name: '.NET Bot Black Sweatshirt',
  description: 'A sweatshirt',
  price: 19.5,
  picture_uri: '/static/images/products/1.png',
  brand_name: '.NET',
  type_name: 'T-Shirt',
};

function LoginDestination() {
  const location = useLocation();
  return <p>Login return: {location.state?.from}</p>;
}

describe('ProductCard favourites', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('sends a signed-out shopper to login with the current catalog location', () => {
    useAuth.mockReturnValue({ isAuthenticated: false, refreshBasket: vi.fn() });

    render(
      <MemoryRouter initialEntries={['/?brand=2&page=1']}>
        <Routes>
          <Route path="/" element={<ProductCard item={item} />} />
          <Route path="/login" element={<LoginDestination />} />
        </Routes>
      </MemoryRouter>,
    );

    fireEvent.click(screen.getByRole('button', { name: `Add ${item.name} to favourites` }));

    expect(screen.getByText('Login return: /?brand=2&page=1')).toBeInTheDocument();
  });

  it('rolls back an optimistic favourite and shows the request error', async () => {
    useAuth.mockReturnValue({ isAuthenticated: true, refreshBasket: vi.fn() });
    let rejectSave;
    api.addFavourite.mockReturnValue(
      new Promise((_, reject) => {
        rejectSave = reject;
      }),
    );

    render(
      <MemoryRouter>
        <ProductCard item={item} />
      </MemoryRouter>,
    );

    const heart = screen.getByRole('button', { name: `Add ${item.name} to favourites` });
    fireEvent.click(heart);
    expect(heart).toHaveAttribute('aria-pressed', 'true');

    rejectSave(new Error('Could not save favourite'));

    await waitFor(() => expect(heart).toHaveAttribute('aria-pressed', 'false'));
    expect(screen.getByRole('alert')).toHaveTextContent('Could not save favourite');
  });

  it('saves a Favourite and notifies the catalog after a successful add', async () => {
    useAuth.mockReturnValue({ isAuthenticated: true, refreshBasket: vi.fn() });
    api.addFavourite.mockResolvedValue(item);
    const onFavouriteChange = vi.fn();

    render(
      <MemoryRouter>
        <ProductCard item={item} onFavouriteChange={onFavouriteChange} />
      </MemoryRouter>,
    );

    const heart = screen.getByRole('button', { name: `Add ${item.name} to favourites` });
    fireEvent.click(heart);

    await waitFor(() => expect(api.addFavourite).toHaveBeenCalledWith(item.id));
    expect(heart).toHaveAttribute('aria-pressed', 'true');
    expect(onFavouriteChange).toHaveBeenCalledWith(item.id, true);
  });

  it('removes a Favourite and notifies the catalog after a successful remove', async () => {
    useAuth.mockReturnValue({ isAuthenticated: true, refreshBasket: vi.fn() });
    api.removeFavourite.mockResolvedValue(null);
    const onFavouriteChange = vi.fn();

    render(
      <MemoryRouter>
        <ProductCard item={item} initialFavourite onFavouriteChange={onFavouriteChange} />
      </MemoryRouter>,
    );

    const heart = screen.getByRole('button', { name: `Remove ${item.name} from favourites` });
    fireEvent.click(heart);

    await waitFor(() => expect(api.removeFavourite).toHaveBeenCalledWith(item.id));
    expect(heart).toHaveAttribute('aria-pressed', 'false');
    expect(onFavouriteChange).toHaveBeenCalledWith(item.id, false);
  });
});

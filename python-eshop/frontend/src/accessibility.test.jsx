import axe from 'axe-core';
import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { expect, it, vi } from 'vitest';
import { useAuth } from './context/AuthContext';
import ProductCard from './components/ProductCard';

vi.mock('./api/client', () => ({
  api: {
    addFavourite: vi.fn(),
    removeFavourite: vi.fn(),
    addToBasket: vi.fn(),
  },
}));

vi.mock('./context/AuthContext', () => ({ useAuth: vi.fn() }));

const item = {
  id: 1,
  name: '.NET Bot Black Sweatshirt',
  description: 'A sweatshirt',
  price: 19.5,
  picture_uri: '/static/images/products/1.png',
  brand_name: '.NET',
  type_name: 'T-Shirt',
};

it('has no automatically detectable WCAG A or AA violations on a catalog card', async () => {
  useAuth.mockReturnValue({ isAuthenticated: true, refreshBasket: vi.fn() });
  const { container } = render(
    <MemoryRouter>
      <ProductCard item={item} />
    </MemoryRouter>,
  );

  const result = await axe.run(container, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22a', 'wcag22aa'] },
    rules: { 'color-contrast': { enabled: false } },
  });

  expect(result.violations).toEqual([]);
});

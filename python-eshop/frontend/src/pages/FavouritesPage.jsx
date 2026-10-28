import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import ProductCard from '../components/ProductCard';
import { useAuth } from '../context/AuthContext';

export default function FavouritesPage() {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login', { replace: true, state: { from: '/favourites' } });
      return;
    }

    setLoading(true);
    setError('');
    api
      .getFavourites()
      .then(setItems)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [isAuthenticated, navigate]);

  function handleFavouriteChange(itemId, isFavourite) {
    if (!isFavourite) {
      setItems((current) => current.filter((item) => item.id !== itemId));
    }
  }

  if (loading) {
    return <p className="text-center text-slate-500">Loading favourites...</p>;
  }

  return (
    <div className="space-y-8">
      <section>
        <p className="text-sm font-semibold uppercase tracking-wider text-indigo-600">Saved for later</p>
        <h1 className="mt-2 text-3xl font-bold text-slate-900">My favourites</h1>
        <p className="mt-2 text-slate-500">Your newest favourites appear first.</p>
      </section>

      {error && (
        <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700" role="alert">
          {error}
        </p>
      )}

      {!error && items.length === 0 ? (
        <div className="card text-center">
          <h2 className="text-xl font-semibold text-slate-900">No favourites yet</h2>
          <p className="mt-2 text-slate-500">Save a catalog item with its heart button to find it here.</p>
          <Link to="/" className="btn-primary mt-5">
            Browse the catalog
          </Link>
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {items.map((item) => (
            <ProductCard
              key={item.id}
              item={item}
              initialFavourite
              onFavouriteChange={handleFavouriteChange}
            />
          ))}
        </div>
      )}
    </div>
  );
}

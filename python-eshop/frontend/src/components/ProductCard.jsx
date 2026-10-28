import { useEffect, useRef, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';

export default function ProductCard({ item, onAdded, initialFavourite = false, onFavouriteChange }) {
  const { isAuthenticated, refreshBasket, sessionVersion } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [isFavourite, setIsFavourite] = useState(initialFavourite);
  const [favouriteLoading, setFavouriteLoading] = useState(false);
  const [favouriteError, setFavouriteError] = useState('');
  const currentSession = useRef(sessionVersion);
  const operationGeneration = useRef(0);
  if (currentSession.current !== sessionVersion) {
    currentSession.current = sessionVersion;
    operationGeneration.current += 1;
  }

  useEffect(() => {
    setIsFavourite(initialFavourite);
    setFavouriteError('');
    setFavouriteLoading(false);
  }, [initialFavourite, sessionVersion]);

  async function handleAdd() {
    setLoading(true);
    setMessage('');
    try {
      await api.addToBasket(item.id);
      await refreshBasket();
      setMessage('Added!');
      onAdded?.();
    } catch (error) {
      setMessage(error.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleFavourite() {
    if (!isAuthenticated) {
      navigate('/login', { state: { from: `${location.pathname}${location.search}` } });
      return;
    }

    const nextFavourite = !isFavourite;
    const requestSession = sessionVersion;
    const requestGeneration = ++operationGeneration.current;
    setIsFavourite(nextFavourite);
    setFavouriteLoading(true);
    setFavouriteError('');
    try {
      if (nextFavourite) {
        await api.addFavourite(item.id);
      } else {
        await api.removeFavourite(item.id);
      }
      if (
        currentSession.current === requestSession &&
        operationGeneration.current === requestGeneration
      ) {
        onFavouriteChange?.(item.id, nextFavourite);
      }
    } catch (error) {
      if (
        currentSession.current === requestSession &&
        operationGeneration.current === requestGeneration
      ) {
        setIsFavourite(!nextFavourite);
        setFavouriteError(error.message);
      }
    } finally {
      if (
        currentSession.current === requestSession &&
        operationGeneration.current === requestGeneration
      ) {
        setFavouriteLoading(false);
      }
    }
  }

  return (
    <article className="card flex flex-col overflow-hidden p-0 transition hover:-translate-y-0.5 hover:shadow-md">
      <div className="relative aspect-square overflow-hidden bg-slate-100">
        <img
          src={item.picture_uri}
          alt={item.name}
          className="h-full w-full object-cover"
        />
        <button
          type="button"
          onClick={handleFavourite}
          disabled={favouriteLoading}
          aria-label={isFavourite ? `Remove ${item.name} from favourites` : `Add ${item.name} to favourites`}
          aria-pressed={isFavourite}
          className="absolute right-3 top-3 flex h-10 w-10 items-center justify-center rounded-full bg-white/95 text-2xl text-rose-600 shadow transition hover:scale-105 disabled:opacity-60"
        >
          <span aria-hidden="true">{isFavourite ? '♥' : '♡'}</span>
        </button>
      </div>
      <div className="flex flex-1 flex-col gap-3 p-4">
        <div className="flex-1">
          <p className="text-xs font-medium uppercase tracking-wide text-indigo-600">
            {item.brand_name} · {item.type_name}
          </p>
          <h3 className="mt-1 text-lg font-semibold text-slate-900">{item.name}</h3>
          <p className="mt-2 text-sm text-slate-500 line-clamp-2">{item.description}</p>
        </div>
        <div className="flex items-center justify-between gap-3">
          <p className="text-xl font-bold text-slate-900">${item.price.toFixed(2)}</p>
          <button
            type="button"
            onClick={handleAdd}
            disabled={loading}
            className="btn-primary"
          >
            {loading ? 'Adding...' : 'Add to basket'}
          </button>
        </div>
        {message && <p className="text-xs font-medium text-emerald-600">{message}</p>}
        {favouriteError && (
          <p className="text-xs font-medium text-red-600" role="alert">
            {favouriteError}
          </p>
        )}
      </div>
    </article>
  );
}

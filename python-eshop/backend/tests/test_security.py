from unittest.mock import Mock, patch

import pytest

from config import Settings
from services.auth_service import AuthService


def test_production_rejects_the_tutorial_signing_secret():
    with pytest.raises(ValueError, match="JWT secret"):
        Settings(environment="production", jwt_secret="tutorial-secret-change-in-production")


def test_unknown_login_still_performs_password_verification():
    db = Mock()
    db.get_user_by_email.return_value = None
    service = AuthService(db, Mock())

    with patch("services.auth_service.verify_password", return_value=False) as verify:
        with pytest.raises(ValueError, match="Invalid email or password"):
            service.login("missing@example.com", "wrong-password")

    verify.assert_called_once()
    assert verify.call_args.args[0] == "wrong-password"


def test_sensitive_api_responses_disable_caching_and_framing(client):
    response = client.post(
        "/api/auth/login",
        json={"email": "missing@example.com", "password": "wrong-password"},
    )

    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["Content-Security-Policy"] == "frame-ancestors 'none'"


def test_public_catalog_is_cacheable_by_the_client(client):
    response = client.get("/api/catalog/items")

    assert "Cache-Control" not in response.headers


def test_static_products_have_an_explicit_public_cache_policy(client):
    response = client.get("/static/images/products/1.png")

    assert response.headers["Cache-Control"] == "public, max-age=3600"

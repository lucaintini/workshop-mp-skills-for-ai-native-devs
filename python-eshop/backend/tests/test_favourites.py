import sqlite3

from fastapi.testclient import TestClient

from config import settings
from tests.conftest import login


def register(client, email: str):
    response = client.post(
        "/api/auth/register",
        json={"email": email, "password": "Pass@word1"},
    )
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def favourite_ids(client, headers):
    response = client.get("/api/favourites", headers=headers)
    assert response.status_code == 200, response.text
    return [item["id"] for item in response.json()]


def test_favourites_require_authentication(client):
    assert client.get("/api/favourites").status_code == 401
    assert client.put("/api/favourites/1").status_code == 401
    assert client.delete("/api/favourites/1").status_code == 401


def test_shopper_can_save_and_remove_a_complete_catalog_item(client, demo_headers):
    saved = client.put("/api/favourites/1", headers=demo_headers)

    assert saved.status_code == 200, saved.text
    assert saved.json() == {
        "id": 1,
        "name": ".NET Bot Black Sweatshirt",
        "description": ".NET Bot Black Sweatshirt",
        "price": 19.5,
        "picture_uri": "/static/images/products/1.png",
        "catalog_brand_id": 2,
        "catalog_type_id": 2,
        "brand_name": ".NET",
        "type_name": "T-Shirt",
    }
    assert favourite_ids(client, demo_headers) == [1]

    removed = client.delete("/api/favourites/1", headers=demo_headers)
    assert removed.status_code == 204
    assert favourite_ids(client, demo_headers) == []


def test_save_and_remove_are_idempotent(client, demo_headers):
    assert client.put("/api/favourites/2", headers=demo_headers).status_code == 200
    assert client.put("/api/favourites/2", headers=demo_headers).status_code == 200
    assert favourite_ids(client, demo_headers) == [2]

    assert client.delete("/api/favourites/2", headers=demo_headers).status_code == 204
    assert client.delete("/api/favourites/2", headers=demo_headers).status_code == 204


def test_favourites_are_private_and_persist_across_login(client, demo_headers):
    other_headers = register(client, "other@perthai.com.au")
    client.put("/api/favourites/3", headers=demo_headers)
    client.put("/api/favourites/4", headers=other_headers)

    assert favourite_ids(client, demo_headers) == [3]
    assert favourite_ids(client, other_headers) == [4]

    signed_in_again = login(client)
    assert favourite_ids(client, signed_in_again) == [3]


def test_favourites_are_newest_saved_first(client, demo_headers):
    client.put("/api/favourites/1", headers=demo_headers)
    client.put("/api/favourites/2", headers=demo_headers)
    client.put("/api/favourites/3", headers=demo_headers)

    assert favourite_ids(client, demo_headers) == [3, 2, 1]


def test_missing_catalog_item_cannot_be_favourited(client, demo_headers):
    response = client.put("/api/favourites/9999", headers=demo_headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Catalog item not found"
    assert favourite_ids(client, demo_headers) == []


def test_favourites_survive_application_restart(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "database_path", str(tmp_path / "restart.db"))
    from main import app

    with TestClient(app) as first_session:
        headers = login(first_session)
        first_session.put("/api/favourites/5", headers=headers)

    with TestClient(app) as restarted_session:
        headers = login(restarted_session)
        assert favourite_ids(restarted_session, headers) == [5]


def test_deleted_catalog_item_disappears_from_favourites(client, demo_headers):
    client.put("/api/favourites/6", headers=demo_headers)

    with sqlite3.connect(settings.database_path) as conn:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.execute("DELETE FROM catalog_items WHERE id = 6")

    assert favourite_ids(client, demo_headers) == []

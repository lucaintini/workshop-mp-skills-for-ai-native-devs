import json
import logging
import uuid

from main import app


@app.get("/api/test/platform-failure", include_in_schema=False)
def platform_failure():
    raise RuntimeError("test failure")


def test_api_responses_include_request_correlation_and_security_headers(client):
    response = client.get("/api/health")

    assert response.status_code == 200
    uuid.UUID(response.headers["X-Request-ID"])
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Referrer-Policy"] == "no-referrer"
    assert response.headers["Permissions-Policy"] == "camera=(), microphone=(), geolocation=()"


def test_valid_request_id_is_preserved_and_logged(client, caplog):
    request_id = str(uuid.uuid4())

    with caplog.at_level(logging.INFO, logger="eshop.http"):
        response = client.get("/api/health", headers={"X-Request-ID": request_id})

    assert response.headers["X-Request-ID"] == request_id
    event = json.loads(caplog.records[-1].message)
    assert event == {
        "duration_ms": event["duration_ms"],
        "http_method": "GET",
        "http_route": "/api/health",
        "http_status_code": 200,
        "request_id": request_id,
    }
    assert event["duration_ms"] >= 0


def test_invalid_request_id_is_replaced(client):
    response = client.get("/api/health", headers={"X-Request-ID": "not-a-uuid"})

    assert response.headers["X-Request-ID"] != "not-a-uuid"
    uuid.UUID(response.headers["X-Request-ID"])


def test_unhandled_failures_are_correlated_and_logged(client, caplog):
    with caplog.at_level(logging.INFO, logger="eshop.http"):
        response = client.get("/api/test/platform-failure")

    assert response.status_code == 500
    uuid.UUID(response.headers["X-Request-ID"])
    assert response.json() == {"detail": "Internal server error"}
    event = json.loads(caplog.records[-1].message)
    assert event["http_status_code"] == 500
    assert event["request_id"] == response.headers["X-Request-ID"]

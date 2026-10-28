import json
import logging
import time
import uuid

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware


logger = logging.getLogger("eshop.http")

SECURITY_HEADERS = {
    "Content-Security-Policy": "frame-ancestors 'none'",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
}

SENSITIVE_PREFIXES = ("/api/auth", "/api/basket", "/api/orders", "/api/favourites")


def request_id_from(value: str | None) -> str:
    if value:
        try:
            return str(uuid.UUID(value))
        except ValueError:
            pass
    return str(uuid.uuid4())


class RequestContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request_id_from(request.headers.get("X-Request-ID"))
        request.state.request_id = request_id
        started = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            logger.exception(
                "Unhandled request failure",
                extra={"request_id": request_id},
            )
            response = JSONResponse({"detail": "Internal server error"}, status_code=500)

        response.headers["X-Request-ID"] = request_id
        for name, value in SECURITY_HEADERS.items():
            response.headers[name] = value
        if request.headers.get("Authorization") or request.url.path.startswith(SENSITIVE_PREFIXES):
            response.headers["Cache-Control"] = "no-store"
        elif request.url.path.startswith("/static/"):
            response.headers["Cache-Control"] = "public, max-age=3600"

        logger.info(
            json.dumps(
                {
                    "duration_ms": round((time.perf_counter() - started) * 1000, 2),
                    "http_method": request.method,
                    "http_route": request.url.path,
                    "http_status_code": response.status_code,
                    "request_id": request_id,
                },
                sort_keys=True,
            )
        )
        return response

from fastapi import APIRouter, Depends, HTTPException, status

from db.client import DatabaseClient
from dependencies import get_db


router = APIRouter(prefix="/api/health", tags=["health"])


@router.get("")
def health():
    """Liveness: the API process can serve requests."""
    return {"status": "ok"}


@router.get("/ready")
def readiness(db: DatabaseClient = Depends(get_db)):
    """Readiness: traffic is safe only while the database responds."""
    if not db.ping():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database unavailable",
        )
    return {"status": "ready"}

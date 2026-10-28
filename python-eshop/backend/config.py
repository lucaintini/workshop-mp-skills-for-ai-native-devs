from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings


DEFAULT_JWT_SECRET = "tutorial-secret-change-in-production"


class Settings(BaseSettings):
    environment: Literal["development", "test", "production"] = "development"
    app_name: str = "eShopOnWeb Python"
    database_path: str = "eshop.db"
    jwt_secret: str = DEFAULT_JWT_SECRET
    jwt_algorithm: str = "HS256"
    jwt_issuer: str = "eshop"
    jwt_audience: str = "eshop-api"
    jwt_expire_minutes: int = 60 * 24
    catalog_page_size: int = 10
    api_host: str = "127.0.0.1"
    api_port: int = 8765
    frontend_port: int = 4321
    cors_origins: list[str] = [
        "http://localhost:4321",
        "http://127.0.0.1:4321",
    ]

    @model_validator(mode="after")
    def production_requires_a_private_signing_secret(self):
        if self.environment == "production" and (
            self.jwt_secret == DEFAULT_JWT_SECRET
            or len(self.jwt_secret.encode("utf-8")) < 32
        ):
            raise ValueError("Production JWT secret must be private and at least 32 bytes")
        return self


settings = Settings()

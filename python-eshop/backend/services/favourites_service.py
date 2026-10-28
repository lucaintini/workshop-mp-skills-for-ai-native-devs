from db.client import DatabaseClient
from models.entities import CatalogItem


class CatalogItemNotFoundError(Exception):
    pass


class FavouritesService:
    def __init__(self, db: DatabaseClient):
        self.db = db

    def list(self, shopper_email: str) -> list[CatalogItem]:
        return self.db.list_favourites(shopper_email)

    def save(self, shopper_email: str, catalog_item_id: int) -> CatalogItem:
        item = self.db.get_catalog_item_by_id(catalog_item_id)
        if item is None:
            raise CatalogItemNotFoundError
        self.db.save_favourite(shopper_email, catalog_item_id)
        return item

    def remove(self, shopper_email: str, catalog_item_id: int) -> None:
        self.db.remove_favourite(shopper_email, catalog_item_id)

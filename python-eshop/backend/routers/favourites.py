from fastapi import APIRouter, Depends, HTTPException, Response, status

from dependencies import get_favourites_service, require_authenticated_user
from models.schemas import CatalogItemResponse
from services.favourites_service import CatalogItemNotFoundError, FavouritesService

router = APIRouter(prefix="/api/favourites", tags=["favourites"])


@router.get("", response_model=list[CatalogItemResponse])
def list_favourites(
    shopper_email: str = Depends(require_authenticated_user),
    service: FavouritesService = Depends(get_favourites_service),
):
    return service.list(shopper_email)


@router.put("/{catalog_item_id}", response_model=CatalogItemResponse)
def save_favourite(
    catalog_item_id: int,
    shopper_email: str = Depends(require_authenticated_user),
    service: FavouritesService = Depends(get_favourites_service),
):
    try:
        return service.save(shopper_email, catalog_item_id)
    except CatalogItemNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Catalog item not found",
        )


@router.delete("/{catalog_item_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_favourite(
    catalog_item_id: int,
    shopper_email: str = Depends(require_authenticated_user),
    service: FavouritesService = Depends(get_favourites_service),
):
    service.remove(shopper_email, catalog_item_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

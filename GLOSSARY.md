# eShop

The eShop context describes how shoppers browse products, save favourites, manage baskets, and place orders.

## Language

**Shopper**:
A person browsing the catalog, authenticated when account-owned capabilities are required.
_Avoid_: Customer, user, buyer

**Catalog item**:
A product offered for sale in the shop.
_Avoid_: Product record, inventory item

**Favourite**:
A catalog item saved by an authenticated Shopper for later consideration.
_Avoid_: Bookmark, saved item, wishlist item

**Favourites collection**:
The ordered set of a Shopper's Favourites, newest saved first.
_Avoid_: Wishlist, saved list

**Basket**:
The set of catalog items and quantities a Shopper intends to purchase.
_Avoid_: Cart, bag

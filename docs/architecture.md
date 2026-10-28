# eShop architecture

These views move from the Shopper's complete journey to the implementation and runtime details. Names match `GLOSSARY.md` and the codebase.

## 1. Shopper-to-product journey

```mermaid
flowchart LR
    Shopper([Shopper])
    Browser[Windows browser]
    Catalog[Browse Catalog]
    Auth{Signed in?}
    Login[Login or register]
    Favourite[Save Favourite]
    Revisit[Open Favourites]
    Basket[Add to Basket]
    Checkout[Checkout]
    Order[View Orders]
    Product[(Catalog product)]

    Shopper --> Browser --> Catalog --> Product
    Product --> Auth
    Auth -- No --> Login --> Catalog
    Auth -- Yes --> Favourite --> Revisit
    Product --> Basket --> Checkout --> Order
    Revisit --> Basket
    Favourite -. preserves product for later .-> Product
```

The Favourites path helps a signed-in Shopper return to a product. It never changes Basket, checkout, or Order state.

## 2. High-level software architecture

```mermaid
flowchart TB
    subgraph Client[Browser process]
        React[React single-page app]
        State[Auth, Basket, and Favourites UI state]
        React <--> State
    end

    subgraph Web[Vite development server :4321]
        Assets[HTML, JavaScript, and CSS]
        Proxy[/API and static proxy/]
    end

    subgraph Api[FastAPI process :8765]
        Routers[HTTP routers]
        Services[Domain services]
        DbClient[Database client]
        Static[Product images]
        Routers --> Services --> DbClient
    end

    Database[(SQLite database)]

    React --> Assets
    React -->|JSON and JWT| Proxy --> Routers
    React -->|image requests| Proxy --> Static
    DbClient -->|parameterised SQL| Database
```

## 3. Low-level Favourites architecture

```mermaid
flowchart LR
    subgraph Frontend
        Header[Header]
        CatalogPage[CatalogPage]
        FavouritesPage[FavouritesPage]
        ProductCard[ProductCard]
        ApiClient[API client]

        Header --> FavouritesPage
        CatalogPage --> ProductCard
        FavouritesPage --> ProductCard
        ProductCard -->|optimistic toggle| ApiClient
        FavouritesPage -->|load collection| ApiClient
    end

    subgraph Backend
        Dependency[Authenticated Shopper dependency]
        Router[Favourites router]
        Service[Favourites service]
        Client[DatabaseClient]

        Dependency --> Router --> Service --> Client
    end

    subgraph Persistence
        Favourites[(favourites<br/>shopper email + catalog item<br/>saved UTC timestamp)]
        Catalog[(catalog_items)]
        Favourites -->|foreign key| Catalog
    end

    ApiClient -->|GET, POST, DELETE /api/favourites| Router
    Client --> Favourites
    Client --> Catalog
```

The unique Shopper/product relationship makes saves idempotent. The authenticated Shopper identity scopes every read and write. Failed optimistic changes roll back in the UI and remain visible as errors.

## 4. Runtime and hardware topology

```mermaid
flowchart TB
    subgraph PC[Windows PC]
        subgraph BrowserHardware[User session]
            Browser[Browser tab]
        end

        subgraph NodeProcess[Node.js process]
            Vite[Vite :4321]
        end

        subgraph PythonProcess[Python process]
            Uvicorn[Uvicorn and FastAPI :8765]
        end

        subgraph Storage[Local disk]
            Source[Repository files]
            SQLite[(eshop.db)]
            Images[Product images]
        end

        Browser -->|HTTP localhost:4321| Vite
        Vite -->|proxy HTTP localhost:8765| Uvicorn
        Vite --> Source
        Uvicorn --> SQLite
        Uvicorn --> Images
    end

    GitHub[GitHub and GitHub Actions]
    Source <-->|Git over HTTPS| GitHub
```

All application traffic stays on the local Windows PC. GitHub stores source history and runs clean-room CI; it does not host the local shop.

## 5. Favourite data flow

```mermaid
sequenceDiagram
    actor Shopper
    participant Card as ProductCard
    participant API as Frontend API client
    participant Auth as Auth dependency
    participant Router as Favourites router
    participant Service as Favourites service
    participant DB as SQLite

    Shopper->>Card: select heart
    Card->>Card: update heart optimistically
    Card->>API: save or remove product
    API->>Auth: request with JWT
    Auth-->>Router: authenticated Shopper email
    Router->>Service: apply Favourite command
    Service->>DB: account-scoped idempotent write
    DB-->>Service: committed result
    Service-->>Router: complete catalog-card data
    Router-->>API: JSON response
    API-->>Card: confirm state

    alt request fails
        API-->>Card: error
        Card->>Card: roll back heart and show error
    end
```

Every boundary is exercised through the FastAPI HTTP seam in backend tests and through component/router behaviour in frontend tests.

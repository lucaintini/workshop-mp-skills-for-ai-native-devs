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
        Context[Correlation, exception logging,<br/>security and cache policy]
        Health[Liveness and database readiness]
        Routers[HTTP routers]
        Services[Domain services]
        DbClient[Database client]
        Static[Product images]
        Context --> Routers --> Services --> DbClient
        Context --> Health --> DbClient
    end

    Database[(SQLite database)]

    React --> Assets
    React -->|JSON, JWT, and request ID| Proxy --> Context
    React -->|image requests| Proxy --> Static
    DbClient -->|parameterised SQL| Database
```

The browser document and API independently emit anti-framing and browser-hardening headers. Authenticated and sensitive responses use `no-store`; public product images have an explicit cache policy. JWTs are bound to the expected issuer and audience, and production refuses the tutorial signing secret.

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

## 4. Local runtime and hardware topology

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

## 5. Delivery, update, and recovery control flow

```mermaid
flowchart LR
    Change[Developer or Dependabot PR]
    Review[Human review]
    CI{Required CI gates}
    Backend[Windows backend tests<br/>lifecycle tests<br/>two Python audits]
    Frontend[Ubuntu frontend tests<br/>axe checks<br/>build and npm audit]
    Artifact[Immutable deployment artifact]
    Canary[Canary instance]
    Ready{Readiness and health objectives}
    Promote[Promote release]
    Rollback[Roll back previous artifact]
    Supervisor[Supervisor with bounded restart backoff]

    Change --> Review --> CI
    CI --> Backend
    CI --> Frontend
    Backend --> Artifact
    Frontend --> Artifact
    Artifact --> Canary --> Ready
    Ready -- healthy --> Promote --> Supervisor
    Ready -- unhealthy --> Rollback
    Supervisor -- dead process --> Supervisor
    Supervisor -- repeated failure --> Rollback
```

Scheduled CI runs weekly to expose runner and dependency drift. Dependabot opens reviewable npm, uv, and GitHub Actions pull requests; it never bypasses tests or silently mutates production. The current repository demonstrates the gates but does not ship a production orchestrator or deployment pipeline.

## 6. Availability and scaling boundary

```mermaid
flowchart TB
    LoadBalancer[Health-aware load balancer]
    Api1[Stateless API replica]
    Api2[Stateless API replica]
    SharedDb[(Managed shared relational database)]
    Secrets[Managed secrets and key rotation]
    Telemetry[Central traces, metrics, and logs]
    Backup[Encrypted backups and restore drills]

    LoadBalancer -->|only ready instances| Api1
    LoadBalancer -->|only ready instances| Api2
    Api1 --> SharedDb
    Api2 --> SharedDb
    Secrets --> Api1
    Secrets --> Api2
    Api1 --> Telemetry
    Api2 --> Telemetry
    SharedDb --> Backup
```

This is the required production target, not the current local topology. SQLite is intentionally a single-instance workshop boundary. Starting multiple API copies against separate local files would create divergent shopper state, so horizontal scaling must wait for shared managed storage, migrations, backup/restore evidence, and stateless instances.

## 7. Favourite and security data flow

```mermaid
sequenceDiagram
    actor Shopper
    participant Card as ProductCard
    participant API as Frontend API client
    participant Context as Request context middleware
    participant Auth as Auth dependency
    participant Router as Favourites router
    participant Service as Favourites service
    participant DB as SQLite

    Shopper->>Card: select heart
    Card->>Card: update heart optimistically
    Card->>API: save or remove product
    API->>Context: request with JWT and optional request ID
    Context->>Context: validate/generate request ID and apply cache policy
    Context->>Auth: decode signed token; verify issuer, audience, and expiry
    Auth-->>Router: authenticated Shopper email
    Router->>Service: apply Favourite command
    Service->>DB: account-scoped idempotent write
    DB-->>Service: committed result
    Service-->>Router: complete catalog-card data
    Router-->>Context: JSON response
    Context-->>API: response with request ID, security and cache headers
    API-->>Card: confirm state

    alt request fails
        Context->>Context: log exception diagnostics with request ID
        API-->>Card: error
        Card->>Card: roll back heart and show error
    end
```

Every boundary is exercised through the FastAPI HTTP seam in backend tests and through component/router behaviour in frontend tests.

## 8. Health and restart sequence

```mermaid
sequenceDiagram
    participant Supervisor
    participant API as FastAPI process
    participant Ready as /api/health/ready
    participant DB as Database
    participant Router as Traffic router

    Supervisor->>API: start process
    Supervisor->>Ready: probe
    Ready->>DB: SELECT 1
    alt database responds
        DB-->>Ready: available
        Ready-->>Supervisor: 200 ready
        Supervisor->>Router: admit instance
    else database unavailable
        Ready-->>Supervisor: 503 unavailable
        Supervisor->>Router: keep instance out of service
        Supervisor->>Supervisor: retry with bounded backoff / alert
    end
    alt process exits
        Supervisor->>API: restart within policy
    end
```

`/api/health` is a liveness signal; `/api/health/ready` additionally probes the database. Restarting a live but dependency-unready process forever is not recovery: production policy should remove it from traffic, retain diagnostics, use bounded retries, and roll back or escalate when the objective gate remains unhealthy.

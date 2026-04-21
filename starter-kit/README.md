# Roadtrip Designer API

REST API for planning roadtrips across Portugal, suggesting Points of Interest along a route.

Built with Ruby on Rails 8 (API mode) + PostgreSQL/PostGIS.

---

## Setup

### Requirements

- Docker + Docker Compose

### Start

```bash
docker compose up --build
```

Starts:

- PostgreSQL 16 with PostGIS 3.4 on port 5432
- Rails API on port 3000
- Runs `db:migrate` and `import:all` on boot — data ready immediately

### Map UI

[http://localhost:3000/map.html](http://localhost:3000/map.html) — interactive trip planner.

- **Dark mode** — CartoDB Dark Matter tiles; full dark UI
- **Color-coded routes** — each stop has a distinct color; the road segment leading to it uses the same color
- **Overlap rendering** — when two route legs share the same road, both colors render as alternating stripes
- **Single OSRM call** — backend fetches the full N-waypoint route with `steps=true&geometries=geojson`, returns per-leg geometry; frontend is a pure display mirror
- **Sidebar sync** — stop cards show the matching color; click any card to pan the map to that stop
- **Nearest POI** — click anywhere on the map to find the closest POI; clicking a stop marker also updates the panel

### Swagger UI

[http://localhost:3000/api-docs](http://localhost:3000/api-docs) — interactive API docs (OpenAPI 3.0).

---

## API Endpoints

### Locations

| Method | Path                    | Description                        |
|--------|-------------------------|------------------------------------|
| GET    | `/api/v1/locations`     | List all locations ordered by name |
| GET    | `/api/v1/locations/:id` | Get a location                     |

```bash
curl http://localhost:3000/api/v1/locations
curl http://localhost:3000/api/v1/locations/1
```

---

### POIs

| Method | Path                                      | Description                    |
|--------|-------------------------------------------|--------------------------------|
| GET    | `/api/v1/pois`                            | List POIs (paginated, 20/page, max 100)      |
| GET    | `/api/v1/pois?category=beach`             | Filter by category             |
| GET    | `/api/v1/pois?page=2&per_page=10`         | Paginate                       |
| GET    | `/api/v1/pois/:id`                        | Get a POI                      |
| GET    | `/api/v1/pois/nearest?lat=37.01&lng=-7.93`| Nearest POI to coordinates     |

```bash
curl http://localhost:3000/api/v1/pois
curl "http://localhost:3000/api/v1/pois?category=beach"
curl "http://localhost:3000/api/v1/pois/nearest?lat=37.0194&lng=-7.9304"
```

---

### Trip Planning

| Method | Path                  | Description    |
|--------|-----------------------|----------------|
| GET    | `/api/v1/trips/plan`  | Plan a roadtrip|

**Parameters:**

| Param            | Required | Description                          |
|------------------|----------|--------------------------------------|
| `origin_id`      | yes      | Location ID for start                |
| `destination_id` | yes      | Location ID for end                  |
| `limit`          | no       | Max stops (default 5, clamped 1–50)  |
| `categories`     | no       | Comma-separated category filter      |

```bash
# Lisboa → Faro, 5 stops
curl "http://localhost:3000/api/v1/trips/plan?origin_id=1&destination_id=3&limit=5"

# Lisboa → Faro, beaches only
curl "http://localhost:3000/api/v1/trips/plan?origin_id=1&destination_id=3&limit=5&categories=beach"

# Porto → Lisboa, nature + viewpoints
curl "http://localhost:3000/api/v1/trips/plan?origin_id=2&destination_id=1&limit=5&categories=nature,viewpoint"
```

**Response:**

```json
{
  "origin": { "id": 1, "name": "Lisboa", "lat": 38.7223, "lng": -9.1393 },
  "destination": { "id": 3, "name": "Faro", "lat": 37.0194, "lng": -7.9304 },
  "stops": [
    {
      "id": 34,
      "name": "Praia de Benagil",
      "lat": 37.0876,
      "lng": -8.4264,
      "categories": ["beach", "nature"],
      "description": "Famous cave beach accessible by boat or kayak."
    }
  ],
  "route_legs": [
    [[lng, lat], [lng, lat], ...],
    ...
  ]
}
```

`route_legs` has one entry per leg (stops + 1). Each entry is an array of `[lng, lat]` pairs representing the road geometry for that segment. `null` if OSRM is unavailable.

---

### Available categories

`beach`, `nature`, `viewpoint`, `culture`, `adventure`, `gastronomy`, `castle`, `monastery`, `waterfall`

---

## Run Tests

```bash
# First time — create and migrate test DB
docker compose exec -e RAILS_ENV=test -e DATABASE_URL=postgis://roadtrip:roadtrip_dev@db:5432/roadtrip_test web bundle exec rails db:drop db:create db:migrate

# Run suite
docker compose exec -e RAILS_ENV=test -e DATABASE_URL=postgis://roadtrip:roadtrip_dev@db:5432/roadtrip_test web bundle exec rspec --format documentation
```

Expected: `33 examples, 0 failures`

---

## CI

GitHub Actions runs on every push and pull request to `main` and `develop`:

- **test** job — spins up PostGIS, runs `db:migrate`, executes the full RSpec suite
- **lint** job — runs RuboCop in parallel

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

---

## Architecture

### Data Model

```text
Location     — city/region with geographic coordinates (PostGIS geography point, SRID 4326)
Poi          — point of interest with coordinates and description
Category     — tag (beach, nature, culture, etc.)
PoiCategory  — join table (Poi ↔ Category, many-to-many)
```

GIST indexes on `locations.coordinates` and `pois.coordinates` for fast spatial queries.

### Trip Planning Algorithm

Two OSRM calls per request:

1. **Corridor call** (`overview=full&geometries=geojson`, 2 waypoints) — gets the actual driving route geometry between origin and destination
2. **Legs call** (`steps=true&geometries=geojson`, N waypoints) — gets per-step road coordinates for all waypoints including selected POIs

POI selection runs entirely in PostgreSQL (`Poi.along_road_route`):

1. Parse OSRM route geometry with `ST_GeomFromGeoJSON`
2. Filter POIs within 50km of that geometry with `ST_DWithin`
3. Exclude POIs within 5km of origin or destination (avoid trivial stops)
4. Order by `ST_Distance` from origin
5. Apply optional category JOIN filter
6. Return up to `limit` stops

If OSRM is unavailable, falls back to `Poi.along_route` — same logic but uses a straight line (`ST_MakeLine`) instead of road geometry.

No data is pulled into Ruby — the full spatial query executes in the database.

### Key Decisions

**PostGIS for all spatial queries** — `ST_Distance`, `ST_DWithin`, `ST_GeomFromGeoJSON`, `ST_MakeLine`, `ST_Azimuth` run in the database. Scales to millions of points without loading data into Rails.

**Geography type (SRID 4326)** — columns use `geography` not `geometry`. Geography operates on a spheroid, so distances are accurate in metres with no manual projection math.

**GIST indexes** — spatial indexes on both coordinate columns make nearest-neighbour and range queries fast.

**`has_many :through` for categories** — explicit `PoiCategory` join model instead of `has_and_belongs_to_many`. Easier to query and extend.

**Pagy for pagination** — lightweight, returns metadata (`total_pages`, `current_page`, `count`) alongside data without loading all records. `per_page` clamped to 100 to prevent full-table dumps.

**Flat JSON serialization** — no serializer gem. Controllers build response hashes directly. Avoids a dependency for a domain this simple.

**Frontend as pure display mirror** — `map.html` makes one API call and renders whatever the backend returns. All routing logic (OSRM, POI selection, leg geometry) lives in Rails. The frontend has no routing code.

**Leaflet + CartoDB Dark Matter** — static HTML in `public/map.html`, no build step. Dark tile layer makes route colors stand out. Falls back to straight dashed lines if `route_legs` is absent.

**rswag for API docs** — Swagger UI served directly from Rails using a hand-written `swagger.yaml`. No code generation needed.

### Security

- **XSS prevention** — all dynamic data passed through `esc()` before `innerHTML` in the map frontend
- **Input validation** — `lat`/`lng` validated against valid coordinate ranges; `per_page` clamped to 1–100
- **No internal error leakage** — `rescue_from StandardError` returns generic 500 message, logs internally

### Trade-offs

**OSRM dependency for POI selection** — calls the public `router.project-osrm.org` to get the actual driving route, then queries POIs within 50km of that geometry. If OSRM is unavailable, falls back to a straight-line corridor. In production, replace with a self-hosted instance.

**50km buffer is a fixed constant** — works well for Portugal's scale. A production API would expose this as a query parameter.

**POI dataset limited to Algarve** — `data/pois.csv` is focused on the southern region. Trips between northern locations (Porto, Coimbra) return few or no stops.

**No auth or rate limiting** — out of scope for the challenge. Production would need JWT auth and Rack::Attack.

**Manual swagger.yaml** — faster to write but will drift from the actual API as endpoints change. Generating from RSpec request specs would keep them in sync.

### What I'd add with more time

1. **Self-hosted OSRM** — eliminate the public `router.project-osrm.org` dependency and rate limit risk
2. **Broader POI dataset** — import data for northern and central Portugal, not just Algarve
3. **Configurable corridor** — expose buffer width and backward-exclusion distance as query parameters
4. **Auth + saved trips** — JWT authentication so users can persist and share trip plans
5. **Generated Swagger** — derive the OpenAPI spec from RSpec request specs to eliminate drift
6. **Transport modes** — walking and cycling profiles via Valhalla (OSRM only supports driving)

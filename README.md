# Indie Campers Technical Challenge

## Junior Fullstack Developer - 2026

Welcome to the Indie Campers technical challenge! We're excited to see how you approach building software.

## The Problem

At Indie Campers, we help travelers explore Portugal in our campervans. We want to build a **Roadtrip Designer API** that suggests interesting points of interest (POIs) along a route between two locations.

### What You'll Build

A REST API that allows users to:

1. **Manage Locations** - Browse available locations (cities) that can serve as trip origin/destination
2. **Manage POIs** - Browse and explore points of interest
3. **Trip Planning** - Given an origin, destination, and desired number of stops, get an ordered list of POIs along the route (filtered optionally by category)
4. **Find Nearest POI** - Given any coordinates, find the closest point of interest

## Provided Materials

We've provided a starter kit to help you focus on the actual challenge:

```
starter-kit/
├── docker-compose.yml      # Postgres + PostGIS configured
├── Dockerfile              # Ruby 3.3 + Rails 8 base
├── Gemfile                 # Core gems (add more as needed)
├── config/
│   └── database.yml        # Database configuration
├── data/
│   ├── locations.csv       # 10 Portuguese cities
│   └── pois.csv            # 100 Points of Interest
└── README.md               # Setup instructions
```

## Requirements

### Core Requirements

| Requirement | Description |
|-------------|-------------|
| **Data Import** | Import the provided CSV files into your database. This should be repeatable (rake task, seeds, etc.) |
| **Data Modeling** | Design your own data model for locations, POIs, and categories. A POI can belong to multiple categories. |
| **Locations API** | Allow users to browse available locations |
| **POIs API** | Allow users to browse and view points of interest |
| **Trip Planning API** | Given an origin, destination, and number of desired POIs, return an ordered list of POIs along the route. Support filtering by category. |
| **Nearest POI** | Given coordinates (lat/lng), return the closest POI |
| **API Documentation** | Swagger/OpenAPI documentation for all endpoints |
| **Tests** | Meaningful test coverage using RSpec |
| **Docker** | `docker-compose up` should start the entire application |
| **README** | Document your architecture decisions, trade-offs, and what you'd improve with more time |

### Technical Stack

- **Ruby**: 3.3+
- **Rails**: 8.0+ (API mode)
- **Database**: PostgreSQL with PostGIS extension
- **Testing**: RSpec
- **Documentation**: Swagger/OpenAPI

You are free to add any additional gems you find useful. Using existing libraries is encouraged when appropriate.

### Bonus (Extra Mile)

These are not required but demonstrate additional skills:

- Frontend with map visualization
- Pagination
- CI/CD configuration (GitHub Actions)
- Deployment documentation

## Guidelines

Focus on building a clean, working solution. We value:

- Clear code over clever code
- Working software over perfect software
- Good decisions you can explain over following patterns blindly

Don't worry about:

- Pixel-perfect UI (if you build a frontend)
- 100% test coverage
- Over-engineering

## Submission

1. Create a **private GitHub repository** with your solution
2. Ensure `docker-compose up` starts everything
3. Include a README with:
   - Setup instructions
   - Architecture decisions and why you made them
   - Trade-offs you considered
   - What you would improve with more time
4. Invite us to your repository (we'll provide the GitHub username)

## Presentation (15-20 minutes)

After reviewing your submission, we'll schedule a remote call where you'll:

1. **Walk us through your solution** (~10 min)
   - Architecture overview
   - Key decisions you made and why
   - Trade-offs you considered

2. **Discussion** (~10 min)
   - Questions about your implementation
   - How you'd extend the system
   - Production considerations (scaling, monitoring, security)

## Timeline

You have **one week** from receiving this challenge to submit your solution. If you need more time, just let us know.

## Questions?

If anything is unclear, please reach out. Asking good questions is part of being a great developer!

---

Good luck, and have fun! We're looking forward to seeing your solution.

*The Indie Campers Engineering Team*

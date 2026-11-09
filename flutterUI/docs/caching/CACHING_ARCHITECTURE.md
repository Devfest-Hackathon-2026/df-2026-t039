# 🚀 Caching System Architecture & Flow

## System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter App UI                             │
│  (HomePage, TripsPage, ProfilePage, SavedPlacesPage, etc)        │
└──────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Service Locator (Singleton)                   │
│  Manages all dependencies, initialized in main()                 │
└──────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
         ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐
         │  TripRepository │ │ PlacesRepository│ │SavedPlacesRep│
         │                 │ │                 │ │              │
         │ listTrips()     │ │getNearbyPlaces()│ │listSavedPlaces
         │ getTrip()       │ │                 │ │createSavedPl.
         │ createTrip()    │ │                 │ │updateSavedPl.
         │ updateTrip()    │ │                 │ │deleteSavedPl.
         │ deleteTrip()    │ │                 │ │              │
         └────────┬────────┘ └────────┬────────┘ └──────┬───────┘
                  │                   │                 │
                  └───────────┬───────┴─────────┬───────┘
                              ▼
                    ┌──────────────────────┐
                    │    ApiProxy          │
                    │                      │
                    │ GET   → Check Cache  │
                    │   │ → Cache HIT ✓    │
                    │   └→ Cache MISS → API
                    │                      │
                    │ POST/PUT/PATCH/DELETE│
                    │ → Execute            │
                    │ → Invalidate Cache   │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
         ┌─────────────────────┐  ┌──────────────────┐
         │   CacheManager      │  │   ApiClient      │
         │                     │  │                  │
         │ Storage: Map<String │  │ HTTP Requests    │
         │ TTL: 5 minutes (def)│  │ Token Management │
         │                     │  │ Error Handling   │
         │ get(key)            │  │                  │
         │ set(key, value, ttl)│  │ request()        │
         │ remove(key)         │  │                  │
         │ removeByPattern()   │  │                  │
         │ cleanup()           │  │                  │
         └─────────────────────┘  └──────────┬───────┘
                    │                        │
                    └───────────┬────────────┘
                                ▼
                    ┌──────────────────────┐
                    │   Backend API        │
                    │                      │
                    │ GET /trips           │
                    │ GET /trips/:id       │
                    │ POST /trips          │
                    │ PATCH /trips/:id     │
                    │ DELETE /trips/:id    │
                    │ ... (other endpoints)│
                    └──────────────────────┘
```

## Data Flow: GET Request with Caching

```
User opens Trips page
        │
        ▼
_loadTrips() called
        │
        ▼
ServiceLocator.tripRepository.listTrips()
        │
        ▼
ApiProxy.getWithCache('/trips', cacheTtl: 300)
        │
        ├─→ Generate cache key: "GET:/trips?limit=20&offset=0"
        │
        ├─→ Check CacheManager.get(key)
        │
        ├─ CACHE HIT (within 5 min TTL)
        │        │
        │        ▼
        │   Return cached data ⚡ (1ms)
        │
        └─ CACHE MISS (expired or new)
                 │
                 ▼
            Call ApiClient.request('GET', '/trips')
                 │
                 ▼
            HTTP GET /trips → Backend
                 │
                 ▼
            Backend processes & returns data
                 │
                 ▼
            CacheManager.set(key, data, ttl: 300)
                 │
                 ▼
            Return data to UI (50-200ms) 📡
                 │
                 ▼
            UI updates with trips
```

## Data Flow: POST Request with Cache Invalidation

```
User clicks "Create Trip"
        │
        ▼
Submit form with trip data
        │
        ▼
ServiceLocator.tripRepository.createTrip(data)
        │
        ▼
ApiProxy.post('/trips', body: data, patterns: ['^GET:/trips'])
        │
        ├─→ Send POST request to backend
        │
        └─→ Backend creates trip, returns 201
                 │
                 ▼
         Invalidate cache using patterns:
         - removeByPattern('^GET:/trips')
                 │
                 ├─→ Remove 'GET:/trips?limit=20'
                 ├─→ Remove 'GET:/trips?limit=20&offset=20'
                 ├─→ Remove 'GET:/trips/upcoming'
                 └─→ Remove 'GET:/trips/123' (detail)
                 │
                 ▼
         Return created trip data
                 │
                 ▼
         Navigate back, refresh UI
                 │
                 ▼
         ServiceLocator.tripRepository.listTrips()
                 │
                 ├─→ Cache is now empty
                 ├─→ Cache MISS → Fetch from backend
                 └─→ Get fresh data with new trip ✅
```

## Cache Key Examples

```
GET /trips?limit=20&offset=0
    ↓
Cache Key: "GET:/trips?limit=20&offset=0"

GET /trips/123
    ↓
Cache Key: "GET:/trips/123"

GET /trips/upcoming
    ↓
Cache Key: "GET:/trips/upcoming"

GET /saved-places?limit=50&offset=0
    ↓
Cache Key: "GET:/saved-places?limit=50&offset=0"

POST /trips (not cached)
GET /messages?limit=50&offset=0
    ↓
Cache Key: "GET:/messages?limit=50&offset=0"
```

## Cache Invalidation Pattern Examples

```
Pattern: ^GET:/trips
├─ Matches: GET:/trips ✓
├─ Matches: GET:/trips?limit=20 ✓
├─ Matches: GET:/trips/123 ✓
├─ Matches: GET:/trips/upcoming ✓
└─ Doesn't match: GET:/places ✗

Pattern: ^GET:/trips/123$
├─ Matches: GET:/trips/123 ✓
├─ Doesn't match: GET:/trips/123/items ✗
└─ Doesn't match: GET:/trips ✗

Pattern: ^GET:/saved-places
├─ Matches: GET:/saved-places ✓
├─ Matches: GET:/saved-places?limit=50 ✓
└─ Doesn't match: GET:/places ✗
```

## Execution Timeline: Typical User Session

```
Time    Action                  Cache Status            API Calls
────────────────────────────────────────────────────────────────
 0ms    Open app
        Load trips              [MISS]                 1. GET /trips
                                ✓ Stored in cache
 50ms   User views trip list
 100ms  Click trip detail       [HIT]                  (from cache)
        Load trip details       [MISS]                 2. GET /trips/:id
                                ✓ Stored in cache
 150ms  View details
 200ms  Return to list          [HIT]                  (from cache)
                                Cache still valid
 250ms  Create new trip
        Submit form             [--]                   3. POST /trips
        Caches invalidated
                                [trips list]
                                [trip detail]
        Return to list
        Load trips              [MISS]                 4. GET /trips
                                ✓ With new trip!
 300ms  View updated list

Total API Calls: 4 (instead of 5 without cache)
Savings: 1 call (20% reduction)

With larger session & more navigation: 30-40% reduction
```

## Cache State Diagram

```
                        ┌─────────────────┐
                        │  Cache Created  │
                        │   (at first GET)│
                        └────────┬────────┘
                                 │
                    ┌────────────┘
                    │
                    ▼
            ┌──────────────────┐
            │   VALID STATE    │
            │ (within TTL)     │
            │                  │
            │ get() → returns  │
            │       cached data│
            └──────────────────┘
                    │
                    │ TTL expires
                    ▼
            ┌──────────────────┐
            │  EXPIRED STATE   │
            │ (beyond TTL)     │
            │                  │
            │ get() → null     │
            │ (triggers MISS)  │
            └──────────────────┘
                    │
                    │ Refresh/cleanup
                    ▼
            ┌──────────────────┐
            │   REMOVED        │
            │ (manually cleared)
            │                  │
            │ Next GET fetches │
            │ fresh from API   │
            └──────────────────┘
                    │
                    │ New data received
                    ▼
            ┌──────────────────┐
            │  Cache Created   │ ← Back to VALID
            │   (new TTL)      │
            └──────────────────┘
```

## Memory Impact

```
Typical App Cache Usage:

Endpoint              Items   Size/Item   Total
─────────────────────────────────────────────
trips list            1       ~500 bytes  500 B
trip details          3       ~1KB        3 KB
upcoming trip         1       ~500 bytes  500 B
saved places          1       ~2KB        2 KB
messages              1       ~1KB        1 KB
─────────────────────────────────────────────
Total                                    ~7 KB

Memory footprint: Negligible (< 1MB for typical app)

At scale with 50 endpoints & 100 items: ~50MB (still very reasonable)
```

## Cost Impact Example

```
Scenario: 10,000 daily users, each uses app for 5 minutes

Endpoint Access Pattern (per session):
- Load trips list: 1 time
- Click trip detail: 2-3 times
- Click saved places: 1 time
- Send messages: 2-3 times
- Navigate back/forth: 3-5 times

WITHOUT CACHE:
Load trips    × 5 accesses = 5 API calls
Trip detail   × 5 accesses = 5 API calls  
Saved places  × 2 accesses = 2 API calls
Messages      × 5 accesses = 5 API calls
─────────────────────────────
Total per user: 17 API calls

10,000 users × 17 calls = 170,000 calls/day

WITH CACHE (5 min TTL):
Load trips    × 1 call (cached 4 times)
Trip detail   × 1 call (cached 4 times)
Saved places  × 1 call (cached 1 time)
Messages      × 2 calls (cached 3 times)
──────────────────────────────
Total per user: 5 API calls

10,000 users × 5 calls = 50,000 calls/day

SAVINGS:
170,000 - 50,000 = 120,000 calls/day avoided
Cost reduction: ~71% 💰

Monthly savings:
120,000 × 30 = 3,600,000 fewer API calls
At $1/1M calls: ~$3.60/month saved
```

## Refresh Strategies

```
User Flow Options:

1. AUTOMATIC REFRESH (Pull-to-Refresh)
   ├─ User pulls down on list
   ├─ _refreshTrips() called
   ├─ forceRefresh: true
   ├─ Cache bypassed → Fresh from backend
   └─ List updates

2. PASSIVE EXPIRATION
   ├─ User navigates away
   ├─ Returns after 5+ minutes
   ├─ TTL expired → Cache miss
   ├─ Automatic fetch from backend
   └─ Fresh data displayed

3. EVENT-DRIVEN INVALIDATION
   ├─ User creates/edits/deletes
   ├─ Mutation operation succeeds
   ├─ Related caches auto-cleared
   ├─ Next access fetches fresh data
   └─ UI reflects changes
```

---

**Understanding the architecture helps with:**
- ✅ Debugging cache issues
- ✅ Configuring TTLs appropriately
- ✅ Implementing cache invalidation patterns
- ✅ Monitoring performance impact
- ✅ Calculating cost savings

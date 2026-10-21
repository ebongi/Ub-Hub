# Feature Ideas

Backlog of proposed features, not yet built. Add to this list as ideas come up.

## Daily study streaks

**Proposed:** 2026-09-29

Daily-engagement gamification layered onto the existing points/leaderboard system (`lib/services/points_service.dart`), with a push reminder before a streak breaks.

- **Why:** The app already has gamification (points, leaderboard) and a subscription system with trial/paid tiers, plus an admin Control Center for managing subscriptions and revenue (see `lib/Screens/UI/preview/Navigation/admin_panel.dart`). Daily engagement is the strongest lever for turning free-trial users into non-churning paying subscribers, and streaks reuse infra that already exists — low effort relative to impact.
- **Watch out for:** Needs a server-side, abuse-resistant definition of "active today" (not just app-open) so streaks can't be gamed trivially.

### Alternatives considered

- **Peer-tutoring marketplace** — bigger and more novel; would reuse `lib/services/marketplace_listing.dart` + chat + the subscription system for paid sessions.
- **Trial-ending push reminders** — smaller, more mechanical win; would reuse `lib/services/notification_service.dart` + the `subscription_expiry` field already tracked on profiles.

# ⛳ Fairway — Ayrshire Golf Companion

A Progressive Web App (PWA) for Ayrshire golfers combining GPS rangefinding, crowd-sourced course conditions, and pro shop loyalty rewards.

No app store required. Golfers access via QR code at the 18th green.

---

## What's in this repo

```
fairway/
├── golfer/
│   └── index.html          # Post-round conditions submission form (mobile-first PWA)
├── greenkeeper/
│   └── index.html          # Private greenkeeper dashboard (conditions + trends)
├── supabase/
│   └── schema.sql          # Full database schema — run in Supabase SQL editor
├── assets/                 # Icons, logos (add icon-192.png and icon-512.png)
├── manifest.json           # PWA manifest
└── README.md
```

---

## Pilot club

**Western Gailes Golf Club**
Gailes, Irvine, KA11 5AE

---

## Tech stack

| Layer | Tool | Cost |
|---|---|---|
| Hosting | GitHub Pages | Free |
| Database & Auth | Supabase | Free tier |
| Weather | Open-Meteo API | Free |
| Maps | Leaflet.js | Free |
| GPS course data | iGolf API | ~£30/mo |
| Email | Resend + Supabase | Free tier |

---

## Getting started

### 1. Supabase setup

1. Create a free account at [supabase.com](https://supabase.com)
2. Create a new project
3. Open the SQL editor and paste the contents of `supabase/schema.sql`
4. Run — this creates all tables, views, and RLS policies
5. Copy your project URL and anon key from **Settings → API**

### 2. Configure environment

Add your Supabase credentials to the front-end files before going live:

```js
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key';
```

> ⚠️ Never commit real keys to a public repo. Use environment variables or GitHub Secrets.

### 3. Deploy to GitHub Pages

1. Push this repo to GitHub
2. Go to **Settings → Pages**
3. Set source to `main` branch, root folder
4. Your app will be live at `https://yourusername.github.io/fairway/`

---

## Points scheme

| Action | Points |
|---|---|
| Round logged | 50 pts |
| First log at a new course | 100 pts |
| 5 rounds in a calendar month | 75 bonus pts |
| Verified handicap member | 2× multiplier |
| Referral | 200 pts |

| Redemption | Points cost |
|---|---|
| £5 pro shop voucher | 500 pts |
| £10 pro shop voucher | 1,000 pts |

Points expire after 12 months. Maximum balance: 5,000 pts.

---

## MVP build order

- [x] Golfer conditions form
- [x] Supabase schema
- [x] Greenkeeper dashboard (dummy data)
- [ ] Supabase auth (user registration / login)
- [ ] Points ledger logic (server-side functions)
- [ ] Voucher generation + email
- [ ] Pro shop redemption page
- [ ] Club admin dashboard
- [ ] GPS rangefinder view
- [ ] Course map (Leaflet.js)
- [ ] Wind overlay (Open-Meteo)
- [ ] PWA offline caching (service worker)
- [ ] Auto hole detection
- [ ] Push notifications

---

## Folder conventions

- `golfer/` — anything the golfer sees on their phone
- `greenkeeper/` — private club-facing views
- `supabase/` — all database migrations and functions
- `assets/` — static assets (icons, QR templates)

---

## Licence

Private repository — not for public distribution during pilot phase.

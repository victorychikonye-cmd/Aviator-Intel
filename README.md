# AVIATOR INTELLIGENCE PRO MAX

Static web app (HTML/JS, no build step) with Supabase auth and storage. For statistical research on historical multiplier data you import yourself. It does not predict outcomes or give betting advice.

## 1. Supabase
1. Create a project at supabase.com.
2. SQL Editor → paste and run `supabase/schema.sql` (tables, indexes, row level security, signup trigger).
3. Authentication → Providers: keep Email enabled. Authentication → URL Configuration: set **Site URL** to your GitHub Pages URL (below) and add it to Redirect URLs (needed for password reset and email confirmation).
4. Project Settings → API: copy the project URL and the publishable (anon) key into `config.js`. Never use the `service_role` key here.

## 2. GitHub Pages
1. Create a repo, push this folder to `main`.
2. Settings → Pages → Source: **GitHub Actions**. The workflow in `.github/workflows/pages.yml` deploys on every push.
3. Your site: `https://<user>.github.io/<repo>/`

## Local test
`python3 -m http.server 8000` then open http://localhost:8000 (add `http://localhost:8000` to Supabase Redirect URLs).

## Data
Import CSV rows as `platform,multiplier,timestamp,source` (platform = Winnbucks, Mwos or PrideBet). Each import creates a dataset and import record. Without config.js values the app runs in offline mode (browser storage only).

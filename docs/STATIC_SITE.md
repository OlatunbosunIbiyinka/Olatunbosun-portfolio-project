# Static site (GitHub Pages)

Always-on portfolio UI while the Azure AKS platform is torn down for cost.

| Item | Value |
|------|--------|
| Source | `app/` (Create React App build) |
| Host | GitHub Pages (Actions deploy) |
| Workflow | `.github/workflows/pages.yml` |
| Domain | `olatunbosun.dev` (`app/public/CNAME`) |
| Cost | Free |

The full private AKS / Argo CD / ACR path remains in this repo — see [QUICK_START.md](QUICK_START.md) to recreate Azure later.

## Enable Pages (one-time)

Repo → **Settings** → **Pages** → Source: **GitHub Actions**.

Or via CLI (after this workflow exists on `main`):

```bash
gh api repos/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/pages \
  -X POST \
  -f build_type=workflow
```

If Pages already exists, set the source to Actions in the UI.

## Porkbun DNS

Remove the old A records that pointed at the AKS Ingress IP (`20.90.229.238`).

For the **apex** domain `olatunbosun.dev`, add **A** records to GitHub Pages:

| Type | Host | Answer | TTL |
|------|------|--------|-----|
| A | (blank / `@`) | `185.199.108.153` | 600 |
| A | (blank / `@`) | `185.199.109.153` | 600 |
| A | (blank / `@`) | `185.199.110.153` | 600 |
| A | (blank / `@`) | `185.199.111.153` | 600 |

Optional `www`:

| Type | Host | Answer | TTL |
|------|------|--------|-----|
| CNAME | `www` | `OlatunbosunIbiyinka.github.io` | 600 |

After DNS propagates, GitHub Pages will issue HTTPS for `olatunbosun.dev` (may take a few minutes to an hour).

## Deploy

Any push to `main` that touches `app/**` runs the Pages workflow. Manual:

```bash
gh workflow run pages.yml
```

## Verify

```bash
curl -sI https://olatunbosun.dev | head -n 15
# Expect: HTTP/2 200 and server headers from GitHub Pages
```

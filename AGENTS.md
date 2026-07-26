# Chatwoot Development Guidelines

## OptimiA — Continuidad entre sesiones (obligatorio)

Este repositorio incluye el producto **OptimiA** (fork de Chatwoot). Git y `docs/project/` son la fuente de verdad compartida entre Cursor Online, Cursor Desktop, Coder y GitHub.

### Antes de modificar código

Ejecutar:

```bash
pwd
git status --short --branch
git branch --show-current
git log -1 --oneline
git remote -v
git fetch origin --prune
git rev-list --left-right --count HEAD...origin/$(git branch --show-current)
```

Opcional: `bash scripts/project-context.sh`

Leer:

- `docs/project/PROJECT-STATUS.md`
- `docs/project/SPRINT-HANDOFF.md`
- `docs/project/DECISIONS.md`
- `docs/project/CHANGELOG.md`
- `docs/optimia/README.md`

### Prohibido sin autorización explícita

- Asumir que la conversación anterior representa el estado actual del repo.
- Sobrescribir cambios desconocidos o iniciar un sprint con trabajo pendiente no comprendido.
- Cambiar de rama, descartar trabajo (`git reset`, `git clean`, force push).
- Inventar decisiones no registradas en `DECISIONS.md` o ADRs.
- Modificar producción, EasyPanel, variables de entorno o imágenes desplegadas.

### Al cerrar un sprint

Actualizar `PROJECT-STATUS.md`, append en `SPRINT-HANDOFF.md`, `CHANGELOG.md`, y registrar decisiones. Ver `.cursor/rules/00-session-continuity.mdc`.

---

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version` (e.g., `rbenv install $(cat .ruby-version)`)
- **rbenv setup**: Before running any `bundle` or `rspec` commands, init rbenv in your shell (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler versions are used
- Always prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:  
  - Do not write custom CSS  
  - Do not use scoped CSS  
  - Do not use inline styles  
  - Always use Tailwind utility classes  
- **Colors**: Refer to `tailwind.config.js` for color definitions

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Ship the happy path first: limit guards/fallbacks to what production has proven necessary, then iterate
- Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
- Prefer `with_modified_env` (from spec helpers) over stubbing `ENV` directly in specs
- Specs in parallel/reloading environments: prefer comparing `error.class.name` over constant class equality when asserting raised errors

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject` (scope optional)
- Example: `feat(auth): add user authentication`
- Don't reference Claude in commit messages

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
- When modifying existing OSS features for Enterprise-only behavior, add an Enterprise module (via `prepend_mod_with`/`include_mod_with`) instead of editing OSS files directly—especially for policies, controllers, and services. For Enterprise-exclusive features, place code directly under `enterprise/`.

## Cursor Cloud specific instructions

The VM snapshot already has the toolchain installed (Ruby 3.4.4 via `rbenv`, Node 24.13.0 via `nvm`, `pnpm`, `overmind`, PostgreSQL 16 with the `pgvector` extension, and Redis). The startup update script only refreshes app dependencies (`bundle install` + `pnpm install`); it does NOT start services. Login shells (`bash -l`) already init `rbenv` + `nvm` and put Node 24 ahead of `/exec-daemon/node`, so run project commands through a login shell (e.g. `bash -lc '...'`).

### Start the stack (each session)

Datastores are not managed by `overmind`, so start them first, then run the dev processes:

```bash
sudo pg_ctlcluster 16 main start   # PostgreSQL on :5432
sudo service redis-server start    # Redis on :6379
overmind start -f ./Procfile.dev   # backend :3000, worker (sidekiq), vite :3036
```

The DB (`chatwoot_dev`) is already created/migrated/seeded in the snapshot. If it is missing, run `bundle exec rails db:prepare` (tests: `RAILS_ENV=test bundle exec rails db:test:prepare`).

### Local `.env` (gitignored, already present in snapshot)

Dev connects to local datastores, not the docker-compose hostnames. Key overrides vs `.env.example`: `POSTGRES_HOST=localhost`, `POSTGRES_USERNAME=postgres`, `POSTGRES_PASSWORD=postgres`, `REDIS_URL=redis://localhost:6379`, a generated `SECRET_KEY_BASE`, and `DISABLE_MINI_PROFILER=true`.

### Gotcha: blank dashboard / requests stuck "pending" in the browser

With `rack-mini-profiler` enabled in development, the browser can hang with all JS module requests stuck in `pending` (HTTP/1.1 6-connection-per-host saturation from long-lived profiler/HMR connections), leaving a blank page even though `curl` returns 200 for every asset. Keep `DISABLE_MINI_PROFILER=true` in `.env` when doing browser/UI testing (this mirrors `Procfile.tunnel`). Restart the `backend` process after changing `.env`.

### Seed login

Dev seeds create SuperAdmin `john@acme.inc` / `Password1!` on account "Acme Inc". App runs at `http://localhost:3000`.

### Notes

- Email delivery uses `/usr/sbin/sendmail`, which is not installed; Sidekiq mailer jobs will fail harmlessly in dev (MailHog is optional).
- Standard build/test/lint commands are documented under **Build / Test / Lint** above.

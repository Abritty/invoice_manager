## Invoice Manager — LLM Build Spec

### Pre-flight: Verify skeleton project
- Ensure environment prerequisites:
  - Ruby version from `.ruby-version` installed and active; Bundler available.
  - PostgreSQL (or configured DB) running if applicable.
- Install and prepare:
  - `bin/setup` (idempotent) — installs gems, sets up DB.
  - `bin/rails db:prepare` — create/migrate test and development DBs.
  - `bin/rails zeitwerk:check` — autoloading OK.
  - `bin/rubocop` and `bin/brakeman -q` — linter/security checks pass or report only acceptable warnings.
  - `bin/rails test` — baseline test suite passes (0 failures).
- Boot check:
  - Start: `bin/dev` (or `bin/rails server`).
  - Verify the app loads at [http://localhost:3000](http://localhost:3000) without errors.
- If any step fails, stop and resolve environment/dependency issues before proceeding to Phase 0.

### Objective
Build a simple invoice management app in Ruby on Rails 8 with Tailwind CSS. Users can create, edit, and delete invoices, upload an invoice PDF, and view a dashboard that shows the percentage breakdown of invoices by status: paid, sent, and overdue.

### Scope
- **Must have**: CRUD for invoices, PDF upload per invoice, dashboard with percentage breakdown (paid/sent/overdue).
- **Out of scope**: Authentication, multi-tenant accounts, payments, emailing, currencies/taxes, pagination, search.

### Tech constraints
- **Framework**: Ruby on Rails 8 (standard MVC, ERB views, no SPA).
- **Styling**: Tailwind CSS (use utility classes, no custom design system).
- **Assets**: Use Rails defaults; do not introduce additional build tools.
- **File storage**: Use Active Storage (local disk in development) for the invoice PDF.

### Data model
- **Table**: `invoices`
  - `company_name` (string, required)
  - `phone_number` (string, required)
  - `invoice_issue_date` (date, required)
  - `payment_date` (date, required) — keep this exact name as provided
  - `state` (string, required; allowed values: `paid`, `sent`, `overdue`)
  - Timestamps
- **Attachment**: `invoice_pdf` via Active Storage (one attached file per invoice; PDF only).

### Business rules
- **Overdue definition**: An invoice is overdue if it is not paid and today is more than 15 days after `invoice_issue_date`.
  - Implementation: treat `overdue` as a stored `state` value that can be updated when listing or saving; or compute dynamically and present as overdue. Prefer computing dynamically for simplicity and accuracy.
- **State meanings**:
  - `paid`: explicitly marked as paid by setting `state` to `paid`.
  - `sent`: created and not paid, and not overdue by rule above.
  - `overdue`: matches the overdue definition above.
- **Dashboard percentages**: Calculate `paid`, `sent`, and `overdue` percentages out of all invoices. If there are zero invoices, display 0% for all to avoid division by zero.

### Validations
- `company_name`: presence.
- `phone_number`: presence; accept only digits, spaces, `+`, `-`, and `(` `)`; length 7–20.
- `invoice_issue_date`: presence; must be on or before today.
- `payment_date`: presence; can be on/after `invoice_issue_date` (do not rename; keep exact field name).
- `state`: presence; inclusion in `paid`, `sent`, `overdue`.
- `invoice_pdf`: content type must be `application/pdf` when attached; file size up to 10 MB.

### UI/Pages
- **Dashboard** (`/dashboard`):
  - Show total counts and percentage breakdown for `paid`, `sent`, `overdue`.
  - A simple bar or donut-like visual using Tailwind (no external chart library; simple CSS-based representation is fine) plus numeric percentages.
- **Invoices index** (`/invoices`): list with columns: company_name, phone_number, invoice_issue_date, payment_date, computed/displayed status, and actions (show/edit/delete).
- **Invoice show**: display all fields and a link to download/view the PDF if attached.
- **Invoice new/edit**: form with all fields and file input for PDF (optional on edit; preserve existing file unless a new one is provided).

### Routing
- `resources :invoices`
- `get "/dashboard", to: "dashboard#show"`
- `root` should redirect to `/dashboard`.

### Implementation details (Rails 8)
1. Generate `Invoice` model and migration with fields above; run migrations.
2. Install Active Storage and run its migrations; attach `invoice_pdf` to `Invoice`.
3. Add model validations; add simple scopes/helpers:
   - `paid` scope: `state = 'paid'`
   - `overdue?` instance method: returns true if not paid and `Date.current > invoice_issue_date + 15.days`.
   - `effective_state` instance method: returns `paid` if `state == 'paid'`, otherwise `overdue` if `overdue?` else `sent`.
4. `InvoicesController`: standard CRUD. When listing and showing, display `effective_state` rather than raw `state` to reflect overdue logic.
5. Views: ERB with Tailwind classes. Use simple, readable layouts. Provide file upload field (`invoice_pdf`) in forms.
6. `DashboardController#show`: compute counts for `paid`, `sent`, `overdue` using `effective_state` logic and return percentages (rounded to whole numbers). Handle zero-total safely.
7. Validation and error messages: render inline in forms using standard Rails helpers.

### Dashboard computation (example)
- `total = Invoice.count`
- `paid_count = Invoice.where(state: 'paid').count`
- `overdue_count = Invoice.all.select(&:overdue?).size` (or a SQL where with date math if preferred)
- `sent_count = total - paid_count - overdue_count`
- Percentages: `((count.to_f / total) * 100).round` when `total > 0`, else 0.

### Acceptance criteria
- I can create, edit, and delete invoices with the specified fields and upload a PDF.
- Dashboard shows accurate percentages for paid, sent, and overdue according to the rules.
- Overdue status is reflected automatically without manual changes once 15 days pass from `invoice_issue_date` (unless the invoice is paid).
- Only PDFs are accepted for upload; invalid inputs show clear errors; no crashes occur.

### Notes for the model names and fields
- Do not rename provided fields. Use exactly: `company_name`, `phone_number`, `invoice_issue_date`, `payment_date`, `state`, and the attachment `invoice_pdf`.
- Keep `state` writable so a user can set `paid`; do not auto-write `overdue` to the database unless explicitly chosen—prefer computing overdue on read.

### Deliverables
- Rails 8 code implementing the above, using Tailwind for styling.
- Migrations, models, controllers, ERB views, routes, and Active Storage configured.
- Minimal seeds (optional) to demo dashboard.

### Testing and quality
- **Test framework**: Use Rails default Minitest (already present under `test/`).
- **Model tests** (`test/models/invoice_test.rb`):
  - Validate presence and formats.
  - Validate `invoice_issue_date` and `payment_date` rules.
  - Unit test `overdue?` and `effective_state` for edge cases: 14, 15, 16 days; and when `state == 'paid'`.
- **Controller/Request tests** (`test/controllers/invoices_controller_test.rb` or `test/integration/invoices_flow_test.rb`):
  - CRUD happy paths and invalid inputs show errors.
  - Attachment upload acceptance (PDF) and rejection (non-PDF).
- **System tests** (`test/system/invoices_test.rb`):
  - Create/edit/delete flows with a minimal UI path.
  - Dashboard shows percent breakdown; zero-invoice case shows 0% each.
- **Fixtures**: Use `test/fixtures/` for simple invoices; prefer explicit values over randomness.
- **Static analysis**:
  - Run RuboCop using the provided configuration: `bin/rubocop`.
  - Run Brakeman for security scanning: `bin/brakeman -q`.
- **Health checks**:
  - `bin/rails zeitwerk:check` for autoloading.
  - `bin/rails db:prepare` before running tests.
- **Local test command**: `bin/rails test` (all tests must pass).

### Best practices
- **Security**: Strong parameters in controllers; rely on Rails CSRF protection; validate content type for uploads; avoid rendering user input without escaping; keep CSP enabled.
- **Performance**: Use eager loading where needed; avoid N+1 in lists (not expected large data sets initially).
- **Maintainability**: Keep controllers thin; move complex logic to model methods or POROs when necessary; keep naming explicit and consistent with field names defined above.
- **Accessibility**: Use semantic HTML in ERB; provide labels for form inputs; ensure color contrast for Tailwind classes.
- **i18n**: Put user-facing strings in `config/locales/en.yml` where practical.
- **Seeds**: Add minimal, idempotent seeds in `db/seeds.rb` to support dashboard demo.
- **Error handling**: Prefer validation errors surfaced in forms; avoid broad `rescue` blocks.

### Phase plan and gating (Agent execution policy)
Divide implementation into sequential phases. After each phase: 1) ensure the app compiles/boots, 2) run linters/security checks, 3) run tests, 4) run the app locally to verify key flows, 5) present a brief summary and ask the User for review/approval before proceeding.

- **Phase 0 — Skeleton verification**
  - Run pre-flight steps above to confirm dependencies, DB, autoloading, lint/security checks, tests, and local boot all succeed.
  - No code changes in this phase; only environment verification.
- **Phase 1 — Data layer**
  - Create `Invoice` model + migration; set up Active Storage and attachment; add validations and model methods (`overdue?`, `effective_state`).
  - Commands: `bin/rails db:prepare && bin/rails db:migrate`; `bin/rails zeitwerk:check`; `bin/rubocop`; `bin/brakeman -q`; `bin/rails test`.
  - Boot check: `bin/dev` starts without errors; terminate after confirmation.
- **Phase 2 — Controller & basic views**
  - Implement `InvoicesController` CRUD, forms (new/edit), index, show; integrate PDF upload.
  - Add corresponding controller and system tests; ensure invalid inputs show errors.
  - Run all checks as above; boot and click through core flows.
- **Phase 3 — Dashboard**
  - Implement `DashboardController#show` and ERB; compute percentages with zero-safe handling and simple Tailwind visualization.
  - Add tests for counts/percentages including zero-invoice case.
  - Run checks; verify visually.
- **Phase 4 — UX polish & accessibility**
  - Improve Tailwind styling, form labels, and table readability.
  - Add minimal i18n wrappers for key strings.
  - Run checks; verify visually.
- **Phase 5 — Seeds and final QA**
  - Add minimal seeds to demonstrate dashboard states; document run steps in `README.md`.
  - Full quality pass (lint, security, tests, boot).

### Review protocol
- After completing each phase, the agent must:
  - Post a short summary of changes, the checks run, and outcomes (pass/fail).
  - Ask the User for review and approval to proceed.
  - Only after explicit approval, begin the next phase.
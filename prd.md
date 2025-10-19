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
Build a comprehensive invoice management app in Ruby on Rails 8 with Tailwind CSS. Authenticated users can create, edit, and delete invoices, generate PDF invoices, view a dashboard with percentage breakdown of invoice statuses, search and filter invoices, and receive notifications about overdue invoices.

### Scope
- **Must have**: User authentication, CRUD for invoices, PDF generation per invoice, dashboard with percentage breakdown (paid/sent/overdue), search functionality, sorting, filtering, notification system, automated overdue detection.
- **Out of scope**: Multi-tenant accounts, payments, emailing, currencies/taxes, pagination.

### Tech constraints
- **Framework**: Ruby on Rails 8 (standard MVC, ERB views, no SPA).
- **Styling**: Tailwind CSS (use utility classes, no custom design system).
- **Assets**: Use Rails defaults; do not introduce additional build tools.
- **Authentication**: Rails 8 default authentication system.
- **PDF Generation**: Use Prawn gem for PDF generation.
- **Background Jobs**: Use Solid Queue for daily overdue detection rake task.

### Data model
- **Table**: `users` (Rails 8 default authentication)
  - Standard authentication fields (email, password, etc.)
  - `has_many :invoices`
- **Table**: `invoices`
  - `user_id` (references users, required)
  - `buyer_name` (string, required) — renamed from company_name
  - `phone_number` (string, required)
  - `invoice_issue_date` (date, required)
  - `payment_date` (date, required)
  - `expiry_date` (date, required) — new field
  - `amount` (decimal, required) — new field
  - `state` (string, required; allowed values: `paid`, `sent`, `overdue`)
  - Timestamps
- **Table**: `notifications` (for overdue invoice alerts)
  - `user_id` (references users, required)
  - `invoice_id` (references invoices, required)
  - `message` (text, required)
  - `read` (boolean, default: false)
  - `created_at` (timestamp)

### Business rules
- **Overdue definition**: An invoice is overdue if it is not paid and today is greater than the invoice's `expiry_date`.
  - Implementation: treat `overdue` as a stored `state` value that can be updated when listing or saving; or compute dynamically and present as overdue. Prefer computing dynamically for simplicity and accuracy.
- **State meanings**:
  - `paid`: explicitly marked as paid by setting `state` to `paid`.
  - `sent`: created and not paid, and not overdue by rule above.
  - `overdue`: not paid and today is greater than the `expiry_date`.
- **Dashboard percentages**: Calculate `paid`, `sent`, and `overdue` percentages out of all invoices for the current user. If there are zero invoices, display 0% for all to avoid division by zero.
- **Authentication**: Users can only see and manage their own invoices.
- **PDF Generation**: Generate PDF invoices on-demand with all invoice details and professional formatting.
- **Notifications**: Users receive notifications for invoices that become overdue after the expiry date.
- **Daily Rake Task**: Automatically identify and update overdue invoices daily.

### Validations
- `buyer_name`: presence.
- `phone_number`: presence; accept only digits, spaces, `+`, `-`, and `(` `)`; length 7–20.
- `invoice_issue_date`: presence; must be on or before today.
- `payment_date`: presence; can be on/after `invoice_issue_date`.
- `expiry_date`: presence; must be on or after `invoice_issue_date`.
- `amount`: presence; must be greater than 0.
- `state`: presence; inclusion in `paid`, `sent`, `overdue`.
- `user_id`: presence (belongs to user).

### UI/Pages
- **Authentication Pages**:
  - Sign up (`/sign_up`)
  - Sign in (`/sign_in`)
  - Sign out (link in navigation)
- **Dashboard** (`/dashboard`):
  - Show total counts and percentage breakdown for `paid`, `sent`, `overdue` for current user.
  - A simple bar or donut-like visual using Tailwind (no external chart library; simple CSS-based representation is fine) plus numeric percentages.
  - Notification bar showing overdue invoices.
- **Invoices index** (`/invoices`): 
  - List with columns: buyer_name, phone_number, invoice_issue_date, payment_date, expiry_date, amount, computed/displayed status, and actions (show/edit/delete/generate_pdf).
  - Search functionality by buyer_name.
  - Sorting by date (ascending/descending) and buyer_name (alphabetical).
  - Filtering by invoice state (paid/sent/overdue).
- **Invoice show**: display all fields and a link to generate/download the PDF.
- **Invoice new/edit**: form with all fields (buyer_name, phone_number, invoice_issue_date, payment_date, expiry_date, amount, state).
- **PDF Generation**: Generate professional PDF invoices with all details.

### Routing
- `resources :sessions, only: [:new, :create, :destroy]` (authentication routes)
- `resources :registrations, only: [:new, :create]` (user registration)
- `resources :invoices` (with authentication required)
- `get "/dashboard", to: "dashboard#show"` (with authentication required)
- `get "/invoices/:id/generate_pdf", to: "invoices#generate_pdf", as: :generate_invoice_pdf` (with authentication required)
- `root` should redirect to `/dashboard` (with authentication required).

### Implementation details (Rails 8)
1. Set up Rails 8 authentication with `rails generate authentication`.
2. Generate `Invoice` model and migration with fields above; run migrations.
3. Generate `Notification` model and migration for overdue alerts.
4. Add model validations; add simple scopes/helpers:
   - `paid` scope: `state = 'paid'`
   - `overdue?` instance method: returns true if not paid and `Date.current > expiry_date`.
   - `effective_state` instance method: returns `paid` if `state == 'paid'`, otherwise `overdue` if `overdue?` else `sent`.
   - `search_by_buyer_name` scope: search invoices by buyer_name.
   - `filter_by_state` scope: filter invoices by state.
5. `InvoicesController`: standard CRUD with authentication. When listing and showing, display `effective_state` rather than raw `state` to reflect overdue logic. Add search, sort, and filter functionality. Add PDF generation action.
6. `DashboardController#show`: compute counts for `paid`, `sent`, `overdue` using `effective_state` logic for current user and return percentages (rounded to whole numbers). Handle zero-total safely. Show notifications.
7. Views: ERB with Tailwind classes. Use simple, readable layouts. Add search, sort, and filter forms. Add notification bar.
8. PDF Generation: Use Prawn gem to generate professional PDF invoices.
9. Rake Task: Create daily task to identify and update overdue invoices, send notifications.
10. Validation and error messages: render inline in forms using standard Rails helpers.

### Dashboard computation (example)
- `total = current_user.invoices.count`
- `paid_count = current_user.invoices.where(state: 'paid').count`
- `overdue_count = current_user.invoices.select(&:overdue?).size` (or a SQL where with date math if preferred)
- `sent_count = total - paid_count - overdue_count`
- Percentages: `((count.to_f / total) * 100).round` when `total > 0`, else 0.

### Acceptance criteria
- I can sign up, sign in, and sign out as a user.
- I can create, edit, and delete invoices with the specified fields (buyer_name, phone_number, invoice_issue_date, payment_date, expiry_date, amount, state).
- I can generate professional PDF invoices for any invoice.
- Dashboard shows accurate percentages for paid, sent, and overdue according to the rules for my invoices only.
- I can search invoices by buyer_name.
- I can sort invoices by date and buyer_name alphabetically.
- I can filter invoices by state (paid/sent/overdue).
- I receive notifications for overdue invoices.
- Overdue status is reflected automatically without manual changes once today is greater than the `expiry_date` (unless the invoice is paid).
- Daily rake task identifies and updates overdue invoices automatically.
- Invalid inputs show clear errors; no crashes occur.

### Notes for the model names and fields
- Use the updated field names: `buyer_name` (renamed from company_name), `phone_number`, `invoice_issue_date`, `payment_date`, `expiry_date`, `amount`, `state`.
- Keep `state` writable so a user can set `paid`; do not auto-write `overdue` to the database unless explicitly chosen—prefer computing overdue on read.
- All invoices must belong to a user (user_id required).
- PDF generation replaces file upload functionality.

### Deliverables
- Rails 8 code implementing the above, using Tailwind for styling.
- Rails 8 authentication setup.
- Migrations, models, controllers, ERB views, routes configured.
- PDF generation functionality using Prawn gem.
- Search, sort, and filter functionality for invoices.
- Notification system for overdue invoices.
- Daily rake task for overdue detection.
- Minimal seeds (optional) to demo dashboard.

### Testing and quality
- **Test framework**: Use Rails default Minitest (already present under `test/`).
- **Model tests** (`test/models/invoice_test.rb`):
  - Validate presence and formats for all fields.
  - Validate `invoice_issue_date`, `payment_date`, and `expiry_date` rules.
  - Unit test `overdue?` and `effective_state` for edge cases: before expiry date, on expiry date, after expiry date; and when `state == 'paid'`.
  - Test search and filter scopes.
- **User model tests** (`test/models/user_test.rb`):
  - Test Rails 8 authentication validations (has_secure_password).
  - Test association with invoices.
- **Controller/Request tests** (`test/controllers/invoices_controller_test.rb` or `test/integration/invoices_flow_test.rb`):
  - CRUD happy paths and invalid inputs show errors.
  - Authentication requirements.
  - Search, sort, and filter functionality.
  - PDF generation.
- **System tests** (`test/system/invoices_test.rb`):
  - Authentication flows (sign up, sign in, sign out).
  - Create/edit/delete flows with a minimal UI path.
  - Dashboard shows percent breakdown; zero-invoice case shows 0% each.
  - Search, sort, and filter functionality.
  - Notification display.
- **Rake task tests** (`test/lib/tasks/overdue_invoices_test.rb`):
  - Test daily overdue detection task.
- **Fixtures**: Use `test/fixtures/` for simple invoices and users; prefer explicit values over randomness.
- **Static analysis**:
  - Run RuboCop using the provided configuration: `bin/rubocop`.
  - Run Brakeman for security scanning: `bin/brakeman -q`.
- **Health checks**:
  - `bin/rails zeitwerk:check` for autoloading.
  - `bin/rails db:prepare` before running tests.
- **Local test command**: `bin/rails test` (all tests must pass).

### Best practices
- **Security**: Strong parameters in controllers; rely on Rails CSRF protection; authenticate all invoice actions; avoid rendering user input without escaping; keep CSP enabled.
- **Performance**: Use eager loading where needed; avoid N+1 in lists; optimize search and filter queries.
- **Maintainability**: Keep controllers thin; move complex logic to model methods or POROs when necessary; keep naming explicit and consistent with field names defined above.
- **Accessibility**: Use semantic HTML in ERB; provide labels for form inputs; ensure color contrast for Tailwind classes.
- **i18n**: Put user-facing strings in `config/locales/en.yml` where practical.
- **Seeds**: Add minimal, idempotent seeds in `db/seeds.rb` to support dashboard demo with sample users and invoices.
- **Error handling**: Prefer validation errors surfaced in forms; avoid broad `rescue` blocks.
- **Background Jobs**: Use Solid Queue for the daily overdue detection task.
- **PDF Generation**: Use Prawn gem for consistent, professional PDF generation.

### Phase plan and gating (Agent execution policy)
Divide implementation into sequential phases, with each phase implemented in a separate git branch. After each phase: 1) ensure the app compiles/boots, 2) run linters/security checks, 3) run tests, 4) run the app locally to verify key flows, 5) commit and push the branch, 6) present a brief summary and ask the User for review/approval before proceeding to the next phase.

### Git Branching Strategy
- **Phase 0**: `phase-0-skeleton-verification`
- **Phase 1**: `phase-1-authentication-data-layer`
- **Phase 2**: `phase-2-controller-basic-views`
- **Phase 3**: `phase-3-pdf-generation`
- **Phase 4**: `phase-4-dashboard-notifications`
- **Phase 5**: `phase-5-rake-task-background-jobs`
- **Phase 6**: `phase-6-ux-polish-accessibility`
- **Phase 7**: `phase-7-seeds-final-qa`
- **Main**: `main` (production-ready code after all phases complete)

- **Phase 0 — Skeleton verification** (`phase-0-skeleton-verification`)
  - Run pre-flight steps above to confirm dependencies, DB, autoloading, lint/security checks, tests, and local boot all succeed.
  - No code changes in this phase; only environment verification.
  - Git: Create and work on `phase-0-skeleton-verification` branch.
- **Phase 1 — Authentication & Data layer** (`phase-1-authentication-data-layer`)
  - Set up Rails 8 authentication; create `User` model.
  - Create `Invoice` model + migration with all fields; create `Notification` model + migration.
  - Add validations and model methods (`overdue?`, `effective_state`, search scopes).
  - Commands: `bin/rails db:prepare && bin/rails db:migrate`; `bin/rails zeitwerk:check`; `bin/rubocop`; `bin/brakeman -q`; `bin/rails test`.
  - Boot check: `bin/dev` starts without errors; terminate after confirmation.
  - Git: Create and work on `phase-1-authentication-data-layer` branch.
- **Phase 2 — Controller & basic views** (`phase-2-controller-basic-views`)
  - Implement `InvoicesController` CRUD with authentication, forms (new/edit), index, show.
  - Add search, sort, and filter functionality.
  - Add corresponding controller and system tests; ensure invalid inputs show errors.
  - Run all checks as above; boot and click through core flows.
  - Git: Create and work on `phase-2-controller-basic-views` branch.
- **Phase 3 — PDF Generation** (`phase-3-pdf-generation`)
  - Implement PDF generation using Prawn gem.
  - Add PDF generation action to `InvoicesController`.
  - Test PDF generation functionality.
  - Run checks; verify PDF generation works.
  - Git: Create and work on `phase-3-pdf-generation` branch.
- **Phase 4 — Dashboard & Notifications** (`phase-4-dashboard-notifications`)
  - Implement `DashboardController#show` and ERB; compute percentages with zero-safe handling and simple Tailwind visualization.
  - Add notification system for overdue invoices.
  - Add tests for counts/percentages including zero-invoice case.
  - Run checks; verify visually.
  - Git: Create and work on `phase-4-dashboard-notifications` branch.
- **Phase 5 — Rake Task & Background Jobs** (`phase-5-rake-task-background-jobs`)
  - Create daily rake task for overdue detection.
  - Set up Solid Queue for background job processing.
  - Test rake task functionality.
  - Run checks; verify background processing.
  - Git: Create and work on `phase-5-rake-task-background-jobs` branch.
- **Phase 6 — UX polish & accessibility** (`phase-6-ux-polish-accessibility`)
  - Improve Tailwind styling, form labels, and table readability.
  - Add minimal i18n wrappers for key strings.
  - Run checks; verify visually.
  - Git: Create and work on `phase-6-ux-polish-accessibility` branch.
- **Phase 7 — Seeds and final QA** (`phase-7-seeds-final-qa`)
  - Add minimal seeds to demonstrate dashboard states; document run steps in `README.md`.
  - Full quality pass (lint, security, tests, boot).
  - Git: Create and work on `phase-7-seeds-final-qa` branch, then merge to `main`.

### Review protocol
- After completing each phase, the agent must:
  - Post a short summary of changes, the checks run, and outcomes (pass/fail).
  - Commit and push the current phase branch to the repository.
  - Ask the User for review and approval to proceed.
  - Only after explicit approval, create and switch to the next phase branch and begin implementation.
# Invoice Manager

A comprehensive invoice management application built with Ruby on Rails 8 and Tailwind CSS.

## Features

- **User Authentication**: Secure user registration, login, and session management
- **Invoice CRUD**: Create, read, update, and delete invoices
- **Invoice Management**: Track invoice states (sent, paid, overdue)
- **Search & Filter**: Search by buyer name, filter by state, sort by various fields
- **Dashboard**: Overview of invoice statistics and recent activity
- **Currency Support**: EUR currency formatting throughout the application
- **Responsive Design**: Beautiful UI built with Tailwind CSS

## Getting Started

### Prerequisites

- Ruby 3.4.2
- Rails 8.0.3
- PostgreSQL (or your preferred database)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. Seed the database with sample data:
   ```bash
   bin/rails db:seed
   ```

5. Start the server:
   ```bash
   bin/rails server
   ```

6. Visit `http://localhost:3000` in your browser

### Sample Data

The seed file creates 2 test users with realistic invoice data using Faker:

- **john.doe@example.com** (password: password123) - 5 invoices
- **jane.smith@example.com** (password: password123) - 5 invoices

Each user has:
- 2 sent invoices (active, awaiting payment)
- 2 paid invoices (completed payments)
- 1 overdue invoice (past due)

All data is generated using the Faker gem with random company names, phone numbers, and amounts between €1,000-€5,000.

### Testing

Run the test suite:
```bash
bundle exec rspec
```

Run specific test files:
```bash
bundle exec rspec spec/models/invoice_spec.rb
bundle exec rspec spec/controllers/invoices_controller_spec.rb
```

## Database Schema

### Users
- `first_name`, `last_name` - User's name
- `email_address` - Unique email (normalized to lowercase)
- `password_digest` - Encrypted password

### Invoices
- `user_id` - Foreign key to users
- `buyer_name` - Company/client name
- `phone_number` - Contact phone number
- `invoice_issue_date` - When invoice was created
- `expiry_date` - Payment due date
- `amount` - Invoice amount in EUR (decimal with precision 10, scale 2)
- `state` - Invoice state (sent, paid, overdue)

## Business Rules

- **Overdue Logic**: An invoice is overdue if it's not paid and today > expiry_date
- **State Management**: States are managed via enum with automatic overdue calculation
- **User Isolation**: Users can only see and manage their own invoices
- **Currency**: All amounts are in EUR with proper formatting

## Development

### Code Quality

Run linters and security checks:
```bash
bin/rubocop
bin/brakeman -q
```

Check autoloading:
```bash
bin/rails zeitwerk:check
```

## License

This project is licensed under the MIT License.

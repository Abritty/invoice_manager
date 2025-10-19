# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

puts "Seeding database with mock data..."

# Clear existing data (only in development)
if Rails.env.development?
  puts "Clearing existing data..."
  Invoice.destroy_all
  User.destroy_all
end

# Create 2 test users
users_data = [
  {
    email_address: "john.doe@example.com",
    first_name: "John",
    last_name: "Doe",
    password: "password123"
  },
  {
    email_address: "jane.smith@example.com",
    first_name: "Jane",
    last_name: "Smith",
    password: "password123"
  }
]

users = users_data.map do |user_data|
  User.find_or_create_by!(email_address: user_data[:email_address]) do |user|
    user.first_name = user_data[:first_name]
    user.last_name = user_data[:last_name]
    user.password = user_data[:password]
    user.password_confirmation = user_data[:password]
  end
end

puts "Created #{users.count} users"

# Valid phone numbers for different regions (phonelib compatible)
phone_numbers = [
  "+1 202 555 1234",
  "+1 202 555 2345", 
  "+1 202 555 3456",
  "+1 202 555 4567",
  "+1 202 555 5678",
  "+44 20 7946 0958",
  "+44 20 7946 0959",
  "+44 20 7946 0960",
  "+44 20 7946 0961",
  "+44 20 7946 0962",
  "+49 30 12345678",
  "+49 30 12345679",
  "+49 30 12345680"
]

# Create 20 invoices for each user with Faker data (to test pagination)
users.each do |user|
  # 8 sent invoices
  8.times do
    issue_date = rand(1..10).days.ago
    Invoice.create!(
      user: user,
      buyer_name: Faker::Company.name,
      phone_number: phone_numbers.sample,
      invoice_issue_date: issue_date,
      expiry_date: issue_date + rand(15..30).days,
      amount: rand(1000..5000).round(2),
      state: :sent
    )
  end

  # 8 paid invoices
  8.times do
    issue_date = rand(20..40).days.ago
    Invoice.create!(
      user: user,
      buyer_name: Faker::Company.name,
      phone_number: phone_numbers.sample,
      invoice_issue_date: issue_date,
      expiry_date: issue_date + rand(5..25).days,
      amount: rand(1000..5000).round(2),
      state: :paid
    )
  end

  # 4 overdue invoices
  4.times do
    issue_date = rand(15..30).days.ago
    Invoice.create!(
      user: user,
      buyer_name: Faker::Company.name,
      phone_number: phone_numbers.sample,
      invoice_issue_date: issue_date,
      expiry_date: issue_date + rand(1..10).days,  # This will be in the past
      amount: rand(1000..5000).round(2),
      state: :sent  # Will be calculated as overdue by the model
    )
  end
end

puts "Created #{Invoice.count} invoices"

# Display summary statistics
puts "\nDatabase Summary:"
puts "Users: #{User.count}"
puts "Invoices: #{Invoice.count}"
puts "Paid invoices: #{Invoice.paid.count}"
puts "Sent invoices: #{Invoice.sent.count}"
puts "Overdue invoices: #{Invoice.select(&:overdue?).count}"

puts "\nTest Users:"
users.each do |user|
  user_invoices = user.invoices
  paid_count = user_invoices.paid.count
  sent_count = user_invoices.sent.count
  overdue_count = user_invoices.select(&:overdue?).count
  
  puts "- #{user.email_address} (#{user.full_name})"
  puts "  Invoices: #{user_invoices.count} (Paid: #{paid_count}, Sent: #{sent_count}, Overdue: #{overdue_count})"
end

puts "\nSeeding completed successfully!"
puts "\nYou can now log in with any of these accounts:"
puts "- john.doe@example.com (password: password123)"
puts "- jane.smith@example.com (password: password123)"

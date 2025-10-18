# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create test users for development and testing
User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

User.find_or_create_by!(email_address: "test@example.com") do |user|
  user.password = "test123"
  user.password_confirmation = "test123"
end

puts "Created test users:"
puts "- admin@example.com (password: password123)"
puts "- test@example.com (password: test123)"

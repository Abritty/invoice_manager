class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :invoices, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :first_name, with: ->(name) { name&.strip&.titleize }
  normalizes :last_name, with: ->(name) { name&.strip&.titleize }

  validates :first_name, :last_name,  presence: true
  validates :email_address, presence: true, uniqueness: true

  def full_name
    "#{first_name} #{last_name}".strip
  end
end

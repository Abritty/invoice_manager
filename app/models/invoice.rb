class Invoice < ApplicationRecord
  belongs_to :user

  enum :state, { sent: 0, paid: 1, overdue: 2 }

  validates :buyer_name, presence: true
  validates :phone_number, presence: true, format: { with: /\A[\d\s\+\-\(\)]+\z/, message: "can only contain digits, spaces, +, -, and ()" }, length: { in: 7..20 }
  validates :invoice_issue_date, presence: true
  validates :expiry_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :state, presence: true

  validate :invoice_issue_date_not_future
  validate :expiry_date_after_issue_date

  scope :search_by_buyer_name, ->(query) { where("buyer_name ILIKE ?", "%#{query}%") }
  scope :filter_by_state, ->(state) { where(state: state) }

  def overdue?
    !paid? && Date.current > expiry_date
  end

  def effective_state
    return 'paid' if paid?
    return 'overdue' if overdue?
    'sent'
  end

  def formatted_amount
    ActionController::Base.helpers.number_to_currency(amount, unit: "€", precision: 2)
  end

  private

  def invoice_issue_date_not_future
    return unless invoice_issue_date.present?
    
    if invoice_issue_date > Date.current
      errors.add(:invoice_issue_date, "cannot be in the future")
    end
  end

  def expiry_date_after_issue_date
    return unless invoice_issue_date.present? && expiry_date.present?
    
    if expiry_date < invoice_issue_date
      errors.add(:expiry_date, "must be on or after invoice issue date")
    end
  end
end

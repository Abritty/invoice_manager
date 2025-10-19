module PhoneNumberValidator
  extend ActiveSupport::Concern

  # Phone number validation message
  PHONE_NUMBER_MESSAGE = "is not a valid phone number"

  included do
    validates :phone_number, presence: true
    validate :phone_number_format
  end

  private

  def phone_number_format
    return if phone_number.blank?
    
    phone = Phonelib.parse(phone_number)
    unless phone.valid?
      errors.add(:phone_number, PHONE_NUMBER_MESSAGE)
    end
  end

  public

  # Helper method to format phone number
  def formatted_phone_number
    return nil if phone_number.blank?
    
    phone = Phonelib.parse(phone_number)
    return phone_number unless phone.valid?
    
    phone.full_e164
  end

  # Helper method to get country code
  def phone_country_code
    return nil if phone_number.blank?
    
    phone = Phonelib.parse(phone_number)
    return nil unless phone.valid?
    
    phone.country_code
  end

  # Helper method to get phone type
  def phone_type
    return nil if phone_number.blank?
    
    phone = Phonelib.parse(phone_number)
    return nil unless phone.valid?
    
    phone.type
  end
end

require 'rails_helper'

RSpec.describe PhoneNumberValidator, type: :model do
  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:invoice) do
    Invoice.new(
      user: user,
      buyer_name: "Test Company",
      phone_number: "+1 202 555 1234",
      invoice_issue_date: Date.current,
      expiry_date: Date.current + 30.days,
      amount: 1000.00,
      state: :sent
    )
  end

  describe 'constants' do
    it 'defines PHONE_NUMBER_MESSAGE constant' do
      expect(PhoneNumberValidator::PHONE_NUMBER_MESSAGE).to be_a(String)
      expect(PhoneNumberValidator::PHONE_NUMBER_MESSAGE).to eq("is not a valid phone number")
    end
  end

  describe 'phone validation' do
    context 'valid phone number formats' do
      valid_phone_numbers = [
        "+1 202 555 1234",        # US Washington DC
        "+1 212 555 1234",        # US New York
        "+1 415 555 1234",        # US San Francisco
        "+44 20 7946 0958",       # UK London
        "+49 30 12345678",        # German Berlin
        "+33 1 42 86 83 26",      # French Paris
        "+81 3 1234 5678",        # Japanese Tokyo
        "+86 10 1234 5678",       # Chinese Beijing
        "+91 11 2345 6789",       # Indian New Delhi
        "+55 11 2345 6789",       # Brazilian São Paulo
        "+61 2 1234 5678",        # Australian Sydney
        "+7 495 123 4567",        # Russian Moscow
        "555-123-4567",           # US without country code
        "(555) 123-4567",         # US with parentheses, no country code
        "5551234567"              # US compact format
      ]

      valid_phone_numbers.each do |phone_number|
        it "accepts #{phone_number}" do
          invoice.phone_number = phone_number
          expect(invoice).to be_valid
        end
      end
    end

    context 'invalid phone number formats' do
      invalid_phone_numbers = [
        "abc-def-ghij",           # Letters
        "123",                    # Too short
        "555-123-4567 ext 123",   # Extension not allowed
        "555-123-4567 x123",      # Extension not allowed
        "555-123-4567*123",       # Invalid characters
        "555-123-4567@123",       # Invalid characters
        "555-123-4567!123",       # Invalid characters
        "555-123-4567?123",       # Invalid characters
        "555-123-4567:123",       # Invalid characters
        "555-123-4567,123",       # Invalid characters
        "555-123-4567.123",       # Invalid characters
        "555-123-4567/123",       # Invalid characters
        "555-123-4567\\123",      # Invalid characters
        "555-123-4567|123",       # Invalid characters
        "555-123-4567<123",       # Invalid characters
        "555-123-4567>123",       # Invalid characters
        "555-123-4567[123",       # Invalid characters
        "555-123-4567]123",       # Invalid characters
        "555-123-4567{123",       # Invalid characters
        "555-123-4567}123",       # Invalid characters
        "555-123-4567^123",       # Invalid characters
        "555-123-4567~123",       # Invalid characters
        "555-123-4567`123",       # Invalid characters
        "555-123-4567'123",       # Invalid characters
        "555-123-4567\"123",      # Invalid characters
        "555-123-4567=123",       # Invalid characters
        "555-123-4567_123",       # Invalid characters
        "555-123-4567%123",       # Invalid characters
        "555-123-4567$123",       # Invalid characters
        "555-123-4567&123",       # Invalid characters
        "555-123-4567|123",       # Invalid characters
        "()+-",                   # Only special characters
        "invalid-phone",          # Mixed invalid
        "123456789012345678901"   # Too long
      ]

      invalid_phone_numbers.each do |phone_number|
        it "rejects #{phone_number}" do
          invoice.phone_number = phone_number
          expect(invoice).not_to be_valid
          expect(invoice.errors[:phone_number]).to include(PhoneNumberValidator::PHONE_NUMBER_MESSAGE)
        end
      end
    end

    context 'presence validation' do
      it 'rejects nil phone number' do
        invoice.phone_number = nil
        expect(invoice).not_to be_valid
        expect(invoice.errors[:phone_number]).to include("can't be blank")
      end

      it 'rejects empty phone number' do
        invoice.phone_number = ""
        expect(invoice).not_to be_valid
        expect(invoice.errors[:phone_number]).to include("can't be blank")
      end
    end
  end

  describe 'helper methods' do
    describe '#formatted_phone_number' do
      it 'returns E164 format for valid phone numbers' do
        invoice.phone_number = "+1 202 555 1234"
        expect(invoice.formatted_phone_number).to eq("+12025551234")
      end

      it 'returns original number for invalid phone numbers' do
        invoice.phone_number = "invalid-phone"
        expect(invoice.formatted_phone_number).to eq("invalid-phone")
      end

      it 'returns nil for blank phone numbers' do
        invoice.phone_number = nil
        expect(invoice.formatted_phone_number).to be_nil
      end

      it 'handles various input formats' do
        test_cases = [
          { input: "+1 (202) 555-1234", expected: "+12025551234" },
          { input: "+1-202-555-1234", expected: "+12025551234" },
          { input: "555-123-4567", expected: "+555551234567" },
          { input: "+44 20 7946 0958", expected: "+442079460958" },
          { input: "+49 30 12345678", expected: "+493012345678" }
        ]

        test_cases.each do |test_case|
          invoice.phone_number = test_case[:input]
          expect(invoice.formatted_phone_number).to eq(test_case[:expected])
        end
      end
    end

    describe '#phone_country_code' do
      it 'returns country code for valid phone numbers' do
        invoice.phone_number = "+1 202 555 1234"
        expect(invoice.phone_country_code).to eq("1")
      end

      it 'returns country code for different countries' do
        test_cases = [
          { phone: "+44 20 7946 0958", country_code: "44" },
          { phone: "+49 30 12345678", country_code: "49" },
          { phone: "+33 1 42 86 83 26", country_code: "33" },
          { phone: "+81 3 1234 5678", country_code: "81" }
        ]

        test_cases.each do |test_case|
          invoice.phone_number = test_case[:phone]
          expect(invoice.phone_country_code).to eq(test_case[:country_code])
        end
      end

      it 'returns nil for invalid phone numbers' do
        invoice.phone_number = "invalid-phone"
        expect(invoice.phone_country_code).to be_nil
      end

      it 'returns nil for blank phone numbers' do
        invoice.phone_number = nil
        expect(invoice.phone_country_code).to be_nil
      end
    end

    describe '#phone_type' do
      it 'returns phone type for valid phone numbers' do
        invoice.phone_number = "+1 202 555 1234"
        expect(invoice.phone_type).to be_in([:mobile, :fixed_line, :fixed_or_mobile])
      end

      it 'returns nil for invalid phone numbers' do
        invoice.phone_number = "invalid-phone"
        expect(invoice.phone_type).to be_nil
      end

      it 'returns nil for blank phone numbers' do
        invoice.phone_number = nil
        expect(invoice.phone_type).to be_nil
      end
    end
  end

  describe 'integration with Invoice model' do
    it 'works with Invoice validations' do
      invoice.phone_number = "+1 202 555 1234"
      expect(invoice).to be_valid
    end

    it 'provides correct error message when validation fails' do
      invoice.phone_number = "invalid-phone"
      invoice.valid?
      expect(invoice.errors[:phone_number]).to include(PhoneNumberValidator::PHONE_NUMBER_MESSAGE)
    end

    it 'works with other Invoice validations' do
      invoice.phone_number = "+1 202 555 1234"
      invoice.buyer_name = "Test Company"
      invoice.amount = 1000.00
      expect(invoice).to be_valid
    end
  end

  describe 'international phone number support' do
    it 'validates phone numbers from different countries' do
      international_numbers = [
        "+1 202 555 1234",        # US Washington DC
        "+44 20 7946 0958",       # UK London
        "+49 30 12345678",        # Germany Berlin
        "+33 1 42 86 83 26",      # France Paris
        "+81 3 1234 5678",        # Japan Tokyo
        "+86 10 1234 5678",       # China Beijing
        "+91 11 2345 6789",       # India New Delhi
        "+55 11 2345 6789",       # Brazil São Paulo
        "+61 2 1234 5678",        # Australia Sydney
        "+7 495 123 4567"         # Russia Moscow
      ]

      international_numbers.each do |phone_number|
        invoice.phone_number = phone_number
        expect(invoice).to be_valid, "Expected #{phone_number} to be valid"
      end
    end
  end

  describe 'edge cases' do
    it 'handles phone numbers with leading/trailing whitespace' do
      invoice.phone_number = "  +1 202 555 1234  "
      expect(invoice).to be_valid
    end

    it 'handles phone numbers with mixed valid and invalid characters' do
      invoice.phone_number = "+1 (202) 555-1234 ext 123"
      expect(invoice).not_to be_valid
      expect(invoice.errors[:phone_number]).to include(PhoneNumberValidator::PHONE_NUMBER_MESSAGE)
    end

    it 'handles very long invalid phone numbers' do
      invoice.phone_number = "123456789012345678901234567890"
      expect(invoice).not_to be_valid
      expect(invoice.errors[:phone_number]).to include(PhoneNumberValidator::PHONE_NUMBER_MESSAGE)
    end
  end

  describe 'performance considerations' do
    it 'validates efficiently with large datasets' do
      start_time = Time.current
      100.times do
        invoice.phone_number = "+1 202 555 1234"
        invoice.valid?
      end
      end_time = Time.current
      expect(end_time - start_time).to be < 1.second
    end
  end

  describe 'phonelib integration' do
    it 'uses phonelib for validation' do
      expect(Phonelib).to receive(:parse).with("+1 202 555 1234").and_call_original
      invoice.phone_number = "+1 202 555 1234"
      invoice.valid?
    end

    it 'handles phonelib parsing errors gracefully' do
      invoice.phone_number = "invalid-phone"
      expect { invoice.valid? }.not_to raise_error
    end
  end
end
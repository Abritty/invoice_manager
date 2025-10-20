require 'rails_helper'

RSpec.describe Invoice, type: :model do
  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:valid_attributes) do
    {
      user: user,
      buyer_name: "Acme Corp",
      phone_number: "+1 202 555 1234",
      invoice_issue_date: Date.current,
      expiry_date: Date.current + 30.days,
      amount: 100.50,
      state: :sent
    }
  end

  let(:invoice) { Invoice.new(valid_attributes) }

  describe 'validations' do
    it 'should be valid with valid attributes' do
      expect(invoice).to be_valid
    end

    it 'should require a user' do
      invoice.user = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:user]).to include("must exist")
    end

    it 'should require buyer_name' do
      invoice.buyer_name = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:buyer_name]).to include("can't be blank")
    end

    it 'should require phone_number' do
      invoice.phone_number = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:phone_number]).to include("can't be blank")
    end

    it 'should validate phone_number format' do
      invoice.phone_number = "invalid-phone"
      expect(invoice).not_to be_valid
      expect(invoice.errors[:phone_number]).to include("is not a valid phone number")
    end

    it 'should validate phone_number length' do
      invoice.phone_number = "123"
      expect(invoice).not_to be_valid
      expect(invoice.errors[:phone_number]).to include("is not a valid phone number")
    end

    it 'should require invoice_issue_date' do
      invoice.invoice_issue_date = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:invoice_issue_date]).to include("can't be blank")
    end

    it 'should require expiry_date' do
      invoice.expiry_date = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:expiry_date]).to include("can't be blank")
    end

    it 'should require amount' do
      invoice.amount = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:amount]).to include("can't be blank")
    end

    it 'should validate amount is greater than 0' do
      invoice.amount = 0
      expect(invoice).not_to be_valid
      expect(invoice.errors[:amount]).to include("must be greater than 0")
    end

    it 'should require state' do
      invoice.state = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:state]).to include("can't be blank")
    end

    it 'should not allow invoice_issue_date in the future' do
      invoice.invoice_issue_date = Date.current + 1.day
      expect(invoice).not_to be_valid
      expect(invoice.errors[:invoice_issue_date]).to include("cannot be in the future")
    end

    it 'should not allow expiry_date before invoice_issue_date' do
      invoice.expiry_date = invoice.invoice_issue_date - 1.day
      expect(invoice).not_to be_valid
      expect(invoice.errors[:expiry_date]).to include("must be on or after invoice issue date")
    end
  end

  describe 'associations' do
    it 'should belong to user' do
      expect(invoice).to respond_to(:user)
      expect(invoice.user).to eq(user)
    end

    it 'should be able to save and retrieve invoice' do
      expect(invoice.save).to be_truthy
      expect(Invoice.exists?(invoice.id)).to be_truthy
    end

    it 'should be destroyed when user is destroyed' do
      invoice.save!
      user_id = user.id
      user.destroy
      expect(Invoice.exists?(user_id: user_id)).to be_falsy
    end
  end

  describe 'enums' do
    it 'should have correct state enum values' do
      expect(Invoice.states).to eq({ 'sent' => 0, 'paid' => 1, 'overdue' => 2 })
    end

    it 'should allow setting state via string' do
      invoice.state = 'paid'
      expect(invoice.state).to eq('paid')
    end

    it 'should allow setting state via symbol' do
      invoice.state = :overdue
      expect(invoice.state).to eq('overdue')
    end
  end

  describe 'scopes' do
    before do
      Invoice.create!(valid_attributes.merge(buyer_name: "Company A", state: :sent))
      Invoice.create!(valid_attributes.merge(buyer_name: "Company B", state: :paid))
      Invoice.create!(valid_attributes.merge(buyer_name: "Another Company", state: :sent))
    end

    describe '.search_by_buyer_name' do
      it 'should find invoices by buyer name' do
        results = Invoice.search_by_buyer_name("Company")
        expect(results.count).to eq(3)
      end

      it 'should be case insensitive' do
        results = Invoice.search_by_buyer_name("company")
        expect(results.count).to eq(3)
      end
    end

    describe '.filter_by_state' do
      it 'should filter by sent state' do
        results = Invoice.filter_by_state('sent')
        expect(results.count).to eq(2)
      end

      it 'should filter by paid state' do
        results = Invoice.filter_by_state('paid')
        expect(results.count).to eq(1)
      end
    end
  end

  describe 'instance methods' do
    describe '#overdue?' do
      it 'should return false for paid invoices' do
        invoice.state = :paid
        expect(invoice.overdue?).to be false
      end

      it 'should return false for sent invoices' do
        invoice.state = :sent
        expect(invoice.overdue?).to be false
      end

      it 'should return true only for invoices with overdue state' do
        invoice.state = :overdue
        expect(invoice.overdue?).to be true
      end
    end

    describe '#effective_state' do
      it 'should return paid for paid invoices' do
        invoice.state = :paid
        expect(invoice.effective_state).to eq('paid')
      end

      it 'should return overdue for invoices with overdue state' do
        invoice.state = :overdue
        expect(invoice.effective_state).to eq('overdue')
      end

      it 'should return sent for sent invoices' do
        invoice.state = :sent
        expect(invoice.effective_state).to eq('sent')
      end
    end

    describe '#formatted_amount' do
      it 'should format amount with EUR symbol' do
        invoice.amount = 123.45
        expect(invoice.formatted_amount).to eq('€123.45')
      end

      it 'should handle zero amount' do
        invoice.amount = 0
        expect(invoice.formatted_amount).to eq('€0.00')
      end
    end
  end

  describe 'class methods' do
    describe '.sent_overdue' do
      let!(:sent_overdue_invoice) do
        Invoice.create!(
          user: user,
          buyer_name: "Overdue Corp",
          phone_number: "+1 202 555 1234",
          invoice_issue_date: Date.current - 10.days,
          expiry_date: Date.current - 1.day,
          amount: 1000.00,
          state: :sent
        )
      end

      let!(:sent_current_invoice) do
        Invoice.create!(
          user: user,
          buyer_name: "Current Corp",
          phone_number: "+1 202 555 2345",
          invoice_issue_date: Date.current - 5.days,
          expiry_date: Date.current + 5.days,
          amount: 2000.00,
          state: :sent
        )
      end

      let!(:paid_overdue_invoice) do
        Invoice.create!(
          user: user,
          buyer_name: "Paid Corp",
          phone_number: "+1 202 555 3456",
          invoice_issue_date: Date.current - 10.days,
          expiry_date: Date.current - 1.day,
          amount: 3000.00,
          state: :paid
        )
      end

      it 'should return only sent invoices past their expiry date' do
        overdue_invoices = Invoice.sent_overdue
        expect(overdue_invoices).to include(sent_overdue_invoice)
        expect(overdue_invoices).not_to include(sent_current_invoice)
        expect(overdue_invoices).not_to include(paid_overdue_invoice)
      end
    end

    describe '.mark_overdue_invoices!' do
      let!(:sent_overdue_invoice) do
        Invoice.create!(
          user: user,
          buyer_name: "Overdue Corp",
          phone_number: "+1 202 555 1234",
          invoice_issue_date: Date.current - 10.days,
          expiry_date: Date.current - 1.day,
          amount: 1000.00,
          state: :sent
        )
      end

      let!(:sent_current_invoice) do
        Invoice.create!(
          user: user,
          buyer_name: "Current Corp",
          phone_number: "+1 202 555 2345",
          invoice_issue_date: Date.current - 5.days,
          expiry_date: Date.current + 5.days,
          amount: 2000.00,
          state: :sent
        )
      end

      it 'should mark sent overdue invoices as overdue' do
        expect { Invoice.mark_overdue_invoices! }
          .to change { sent_overdue_invoice.reload.state }
          .from('sent').to('overdue')
      end

      it 'should not change current sent invoices' do
        expect { Invoice.mark_overdue_invoices! }
          .not_to change { sent_current_invoice.reload.state }
      end
    end
  end

  describe 'timestamps' do
    it 'should have timestamps' do
      invoice.save!
      expect(invoice.created_at).not_to be_nil
      expect(invoice.updated_at).not_to be_nil
    end
  end
end

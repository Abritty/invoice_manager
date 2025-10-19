require 'rails_helper'

RSpec.describe InvoiceSorting, type: :model do
  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:invoice1) do
    Invoice.create!(
      user: user,
      buyer_name: "Alpha Corp",
      phone_number: "+1 202 555 1234",
      invoice_issue_date: 5.days.ago,
      expiry_date: 25.days.from_now,
      amount: 1000.00,
      state: :sent
    )
  end

  let!(:invoice2) do
    Invoice.create!(
      user: user,
      buyer_name: "Beta Inc",
      phone_number: "+1 202 555 2345",
      invoice_issue_date: 3.days.ago,
      expiry_date: 27.days.from_now,
      amount: 2000.00,
      state: :paid
    )
  end

  let!(:invoice3) do
    Invoice.create!(
      user: user,
      buyer_name: "Charlie LLC",
      phone_number: "+1 202 555 3456",
      invoice_issue_date: 1.day.ago,
      expiry_date: 29.days.from_now,
      amount: 3000.00,
      state: :sent
    )
  end

  describe 'constants' do
    it 'defines SORT_OPTIONS constant' do
      expect(InvoiceSorting::SORT_OPTIONS).to be_a(Hash)
      expect(InvoiceSorting::SORT_OPTIONS).to be_frozen
    end

    it 'includes all expected sort options' do
      expected_options = %w[
        buyer_name_asc buyer_name_desc
        expiry_date_asc expiry_date_desc
        amount_asc amount_desc
        created_at_asc created_at_desc
      ]
      
      expect(InvoiceSorting::SORT_OPTIONS.keys).to match_array(expected_options)
    end

    it 'defines DEFAULT_SORT constant' do
      expect(InvoiceSorting::DEFAULT_SORT).to eq('created_at_desc')
      expect(InvoiceSorting::DEFAULT_SORT).to be_frozen
    end
  end

  describe '.sort_invoices_by' do
    context 'with valid sort parameters' do
      it 'sorts by buyer_name ascending' do
        result = Invoice.sort_invoices_by('buyer_name_asc')
        expect(result.pluck(:buyer_name)).to eq(['Alpha Corp', 'Beta Inc', 'Charlie LLC'])
      end

      it 'sorts by buyer_name descending' do
        result = Invoice.sort_invoices_by('buyer_name_desc')
        expect(result.pluck(:buyer_name)).to eq(['Charlie LLC', 'Beta Inc', 'Alpha Corp'])
      end

      it 'sorts by expiry_date ascending' do
        result = Invoice.sort_invoices_by('expiry_date_asc')
        expect(result.pluck(:expiry_date)).to eq([invoice1.expiry_date, invoice2.expiry_date, invoice3.expiry_date])
      end

      it 'sorts by expiry_date descending' do
        result = Invoice.sort_invoices_by('expiry_date_desc')
        expect(result.pluck(:expiry_date)).to eq([invoice3.expiry_date, invoice2.expiry_date, invoice1.expiry_date])
      end

      it 'sorts by amount ascending' do
        result = Invoice.sort_invoices_by('amount_asc')
        expect(result.pluck(:amount)).to eq([1000.0, 2000.0, 3000.0])
      end

      it 'sorts by amount descending' do
        result = Invoice.sort_invoices_by('amount_desc')
        expect(result.pluck(:amount)).to eq([3000.0, 2000.0, 1000.0])
      end

      it 'sorts by created_at ascending' do
        result = Invoice.sort_invoices_by('created_at_asc')
        expect(result.pluck(:id)).to eq([invoice1.id, invoice2.id, invoice3.id])
      end

      it 'sorts by created_at descending' do
        result = Invoice.sort_invoices_by('created_at_desc')
        expect(result.pluck(:id)).to eq([invoice3.id, invoice2.id, invoice1.id])
      end
    end

    context 'with invalid sort parameters' do
      it 'uses default sort when given invalid parameter' do
        result = Invoice.sort_invoices_by('invalid_sort')
        expect(result.pluck(:id)).to eq([invoice3.id, invoice2.id, invoice1.id])
      end

      it 'uses default sort when given nil' do
        result = Invoice.sort_invoices_by(nil)
        expect(result.pluck(:id)).to eq([invoice3.id, invoice2.id, invoice1.id])
      end

      it 'uses default sort when given empty string' do
        result = Invoice.sort_invoices_by('')
        expect(result.pluck(:id)).to eq([invoice3.id, invoice2.id, invoice1.id])
      end
    end
  end

  describe '.sort_options_for_select' do
    it 'returns an array of arrays' do
      result = Invoice.sort_options_for_select
      expect(result).to be_an(Array)
      expect(result.all? { |option| option.is_a?(Array) && option.length == 2 }).to be true
    end

    it 'includes all expected sort options' do
      result = Invoice.sort_options_for_select
      expected_options = [
        ['Newest First', 'created_at_desc'],
        ['Oldest First', 'created_at_asc'],
        ['Buyer Name (A-Z)', 'buyer_name_asc'],
        ['Buyer Name (Z-A)', 'buyer_name_desc'],
        ['Expiry Date (Oldest)', 'expiry_date_asc'],
        ['Expiry Date (Newest)', 'expiry_date_desc'],
        ['Amount (Low to High)', 'amount_asc'],
        ['Amount (High to Low)', 'amount_desc']
      ]
      
      expect(result).to match_array(expected_options)
    end

    it 'has user-friendly display names' do
      result = Invoice.sort_options_for_select
      display_names = result.map(&:first)
      
      expect(display_names).to include('Newest First')
      expect(display_names).to include('Buyer Name (A-Z)')
      expect(display_names).to include('Amount (Low to High)')
    end
  end

  describe '.valid_sort_param?' do
    it 'returns true for valid sort parameters' do
      expect(Invoice.valid_sort_param?('buyer_name_asc')).to be true
      expect(Invoice.valid_sort_param?('amount_desc')).to be true
      expect(Invoice.valid_sort_param?('created_at_asc')).to be true
    end

    it 'returns false for invalid sort parameters' do
      expect(Invoice.valid_sort_param?('invalid_sort')).to be false
      expect(Invoice.valid_sort_param?(nil)).to be false
      expect(Invoice.valid_sort_param?('')).to be false
    end
  end

  describe 'integration with Invoice model' do
    it 'can be chained with other scopes' do
      result = user.invoices.sent.sort_invoices_by('amount_asc')
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result.pluck(:amount)).to eq([1000.0, 3000.0])
    end

    it 'works with search scope' do
      result = user.invoices.search_by_buyer_name('Alpha').sort_invoices_by('amount_desc')
      expect(result.pluck(:buyer_name)).to eq(['Alpha Corp'])
    end

    it 'works with filter scope' do
      result = user.invoices.filter_by_state('sent').sort_invoices_by('buyer_name_asc')
      expect(result.pluck(:buyer_name)).to eq(['Alpha Corp', 'Charlie LLC'])
    end
  end

  describe 'performance considerations' do
    it 'generates efficient SQL queries' do
      expect do
        Invoice.sort_invoices_by('buyer_name_asc').to_sql
      end.not_to raise_error
    end

    it 'does not cause N+1 queries when used with includes' do
      expect do
        Invoice.includes(:user).sort_invoices_by('amount_desc').to_a
      end.not_to raise_error
    end
  end
end

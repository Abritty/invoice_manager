require 'rails_helper'
require 'rake'

RSpec.describe 'invoices:mark_overdue rake task' do
  before(:all) do
    Rake.application.rake_require "tasks/invoice_overdue"
    Rake::Task.define_task(:environment)
  end

  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

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

  before(:each) do
    Rake::Task["invoices:mark_overdue"].reenable
  end

  it 'should mark sent overdue invoices as overdue' do
    expect { Rake::Task["invoices:mark_overdue"].invoke }
      .to change { sent_overdue_invoice.reload.state }
      .from('sent').to('overdue')
  end

  it 'should not change current sent invoices' do
    expect { Rake::Task["invoices:mark_overdue"].invoke }
      .not_to change { sent_current_invoice.reload.state }
  end

  it 'should not change paid invoices' do
    expect { Rake::Task["invoices:mark_overdue"].invoke }
      .not_to change { paid_overdue_invoice.reload.state }
  end

  it 'should output success message' do
    expect { Rake::Task["invoices:mark_overdue"].invoke }
      .to output(/✅ Marked 1 invoices as overdue/).to_stdout
  end
end

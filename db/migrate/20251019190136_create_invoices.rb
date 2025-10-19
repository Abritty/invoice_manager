class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :buyer_name
      t.string :phone_number
      t.date :invoice_issue_date
      t.date :expiry_date
      t.decimal :amount, precision: 10, scale: 2
      t.integer :state, default: 0

      t.timestamps
    end

    add_index :invoices, :buyer_name
    add_index :invoices, :state
    add_index :invoices, :expiry_date
    add_index :invoices, [:user_id, :state]
    add_index :invoices, [:user_id, :expiry_date]
  end
end

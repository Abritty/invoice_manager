class AddUserStateExpiryIndexToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_index :invoices,
              [:user_id, :state, :expiry_date],
              name: "index_invoices_on_user_state_expiry_date"
  end
end



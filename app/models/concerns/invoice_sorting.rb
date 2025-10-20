module InvoiceSorting
  extend ActiveSupport::Concern

  # Available sorting options
  SORT_OPTIONS = {
    'buyer_name_asc' => { field: :buyer_name, direction: :asc },
    'buyer_name_desc' => { field: :buyer_name, direction: :desc },
    'expiry_date_asc' => { field: :expiry_date, direction: :asc },
    'expiry_date_desc' => { field: :expiry_date, direction: :desc },
    'amount_asc' => { field: :amount, direction: :asc },
    'amount_desc' => { field: :amount, direction: :desc },
    'created_at_asc' => { field: :created_at, direction: :asc },
    'created_at_desc' => { field: :created_at, direction: :desc }
  }.freeze

  # Default sorting option
  DEFAULT_SORT = 'created_at_desc'.freeze

  class_methods do
    # Sort invoices based on the provided sort parameter
    def sort_invoices_by(sort_param)
      sort_option = SORT_OPTIONS[sort_param] || SORT_OPTIONS[DEFAULT_SORT]
      order(sort_option[:field] => sort_option[:direction])
    end

    # Get all available sort options for forms
    def sort_options_for_select
      [
        ['Newest First', 'created_at_desc'],
        ['Oldest First', 'created_at_asc'],
        ['Buyer Name (A-Z)', 'buyer_name_asc'],
        ['Buyer Name (Z-A)', 'buyer_name_desc'],
        ['Expiry Date (Oldest)', 'expiry_date_asc'],
        ['Expiry Date (Newest)', 'expiry_date_desc'],
        ['Amount (Low to High)', 'amount_asc'],
        ['Amount (High to Low)', 'amount_desc']
      ]
    end

    # Validate if a sort parameter is valid
    def valid_sort_param?(sort_param)
      SORT_OPTIONS.key?(sort_param)
    end
  end
end

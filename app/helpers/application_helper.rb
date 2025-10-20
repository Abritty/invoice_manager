module ApplicationHelper
  def invoice_status_classes(invoice)
    case invoice.effective_state
    when 'paid'
      'bg-green-100 text-green-800'
    when 'overdue'
      'bg-red-100 text-red-800'
    else
      'bg-yellow-100 text-yellow-800'
    end
  end
end

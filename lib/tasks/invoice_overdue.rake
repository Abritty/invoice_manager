namespace :invoices do
  desc "Mark sent invoices as overdue if their expiry date has passed"
  task mark_overdue: :environment do
    puts "Checking for overdue invoices..."
    
    overdue_count = Invoice.sent_overdue.count
    
    if overdue_count > 0
      Invoice.mark_overdue_invoices!
      puts "✅ Marked #{overdue_count} invoices as overdue"
    else
      puts "✅ No invoices need to be marked as overdue"
    end
    
    puts "Overdue invoice check completed at #{Time.current}"
  end
end

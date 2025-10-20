# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Set the environment and output log file
set :environment, ENV['RAILS_ENV'] || 'development'
set :output, "log/cron.log"
set :job_template, "/bin/bash -l -c ':job'"

# Run the invoice overdue task every day at 12:00 AM
every 1.day, at: '12:00 am' do
  rake "invoices:mark_overdue"
end

# Learn more: http://github.com/javan/whenever

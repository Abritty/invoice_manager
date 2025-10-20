namespace :cron do
  desc "Show the current cron schedule"
  task :show do
    puts "Current cron schedule:"
    puts `bundle exec whenever`
  end

  desc "Install the cron job (requires sudo)"
  task :install do
    puts "Installing cron job..."
    puts "This will run: bundle exec whenever --update-crontab"
    puts "You may need to enter your password for sudo access."
    system "bundle exec whenever --update-crontab"
  end

  desc "Remove the cron job"
  task :remove do
    puts "Removing cron job..."
    system "bundle exec whenever --clear-crontab"
  end

  desc "Update the cron job"
  task :update do
    puts "Updating cron job..."
    system "bundle exec whenever --update-crontab"
  end
end

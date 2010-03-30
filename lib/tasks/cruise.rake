class CustomLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{msg}\n"
  end
end

namespace :cruise do
  task :prepare => :environment do
    $logfile = File.open(Rails.root.join("log/cruise.log"), "a")
    $logfile.sync = true
    $logger = CustomLogger.new($logfile)
    $logger.info "Starting #{Time.now}"
    ENV['PLUGIN'] = "mh_common/lib/common/core/ca/\\|mh_common/lib/legacy/\\|mh_common/lib/pulse/"
    $lock_path = File.expand_path("~/.cruise/mh_common_lock")
    while File.exists?($lock_path)
      $logger.info "Detected another test going on.  Waiting 30 seconds."
      sleep 30
    end
    $logger.info "Locking mh_common"
    $lock = File.open($lock_path, "w")
  end
end

task :cruise => [ "cruise:prepare" ] do
  Rake::Task["test:coverage:plugin:units"].execute
  $logger.info "Finished tests, closing lock"
  $lock.close
  File.delete($lock_path)
  $logger.info "Done #{Time.now}"
end

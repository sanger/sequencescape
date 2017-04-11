namespace :tmp do
  namespace :carrierwave do
    desc 'Remove the past 24h of cached carrierwave files'
    task cleanup: :environment do
      PolymorphicUploader.clean_cached_files!
    end
  end
end

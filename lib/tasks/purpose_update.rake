namespace :purpose do
  desc 'Automatically generate absent purposes'
  task update: :environment do
    RecordLoader::PlatePurposeLoader.new.create!
  end
end

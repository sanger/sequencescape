require File.expand_path(File.join(Rails.root, %w{test factories.rb}))

Dir.glob(File.expand_path(File.join(Rails.root, %w{test factories ** *.rb}))) do |factory_filename|
  require factory_filename
end

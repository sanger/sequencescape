Tempfile.open("config") do |tempfile|
  config = ERB.new((IO.read("#{RAILS_ROOT}/config/config.yml"))).result
  tempfile.write(config)
  tempfile.flush
  configatron.configure_from_yaml(tempfile.path , :hash => Rails.env)
end

require "#{Rails.root}/config/config.rb"
# Converting config.yml
#  config = ERB.new((IO.read("#{Rails.root}/config/config.yml"))).result
# yam=YAML::load(config)

# def take_step(address,option,value)
#   if value.is_a?(Hash)
#     value.each do |k,v|
#       take_step((address+[option]),k,v)
#     end
#   else
#     puts "  #{(address+[option]).join('.')} = #{value.inspect}"
#   end
# end

# address = ['configatron']

# yam.each do |env,options|
#   puts "if Rails.env == '#{env}'"
#   options.each do |k,v|
#     take_step(address,k,v)
#   end
#   puts "end"
# end

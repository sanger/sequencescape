# frozen_string_literal: true
#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
# ActiveMessaging::Gateway.define do |s|
#   #s.destination :orders, '/queue/Orders'
#   #s.filter :some_filter, :only=>:orders
#   #s.processor_group :group1, :order_processor

#   s.destination :qc_evaluations, "/queue/#{Rails.env}.qc_evaluations", {:ack=>'client', :persistent => false}

# end

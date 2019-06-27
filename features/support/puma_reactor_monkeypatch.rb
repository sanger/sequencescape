# frozen_string_literal: true

# Patch from
# https://gist.github.com/2rba/74d57775ac83ffcb0ff1da5eb5371212
# See issue:
# https://github.com/puma/puma/issues/1582
# require 'puma/reactor'

# module CoreExtensions
#   module Puma
#     # The overriding of time functionality with TimeCop or the
#     # ActiveSupport::TimeHelpers causes puma to get confused and generate
#     # invalid time-outs, which get it caught in a loop.
#     module Reactor
#       def calculate_sleep
#         if @timeouts.empty?
#           @sleep_for = ::Puma::Reactor::DefaultSleepFor
#         else
#           diff = @timeouts.first.timeout_at.to_f - ::Time.now.to_f

#           @sleep_for = if diff < 0.0
#                          0
#                        elsif diff > 60
#                          ::Puma::Reactor::DefaultSleepFor
#                        else
#                          diff
#                        end
#         end
#       end
#     end
#   end
# end

# Puma::Reactor.prepend CoreExtensions::Puma::Reactor

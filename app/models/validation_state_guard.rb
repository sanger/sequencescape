# frozen_string_literal: true
# It's such a common pattern in the code to have a guard on some our validations that this module provides
# that facility.  You can declare a guard with:
#
#     extend ValidationStateGuard
#     validation_guard(:guard_name)
#
# This then gives you *private* methods of guard_name, guard_name=, and guard_name?  It also adds an after_save
# callback that ensures that guard_name is false so it doesn't leak.
#
# If you have a method that should enable a guard and then disable it afterwards then you can do:
#
#     validation_guarded_by(:method_that_needs_guard_enabled, :guard_name)
#
# This will set the guard_name to true before the method is called and return it to false afterwards.
#
# JG: This pattern has been pretty much eliminated. It seems to just be used to control {Sample} renaming
module ValidationStateGuard
  def validation_guard(guard)
    guard = guard.to_sym

    line = __LINE__ + 1
    class_eval(
      "
      attr_accessor #{guard.inspect}
      alias_method(#{guard.inspect}?, #{guard.inspect})
      private #{guard.inspect}, #{guard.inspect}?
      # This used to be protected, looks like rails attribute assignment implementation changed.
      public #{guard.inspect}=

      # Do not remove the 'true' from this otherwise the return value is false, which will fail the save!
      after_save { |record| record.send(#{guard.inspect}=, false) ; true }
    ",
      __FILE__,
      __LINE__ - 11
    )
  end

  def validation_guarded_by(method, guard) # rubocop:todo Metrics/MethodLength
    # Method name could end in ! or ?, in which case the unguarded name needs to be correct.
    method.to_s =~ /^([^!?]+)([!?])?$/
    core_name = ::Regexp.last_match(1)
    extender = ::Regexp.last_match(2)
    unguarded_name = :"#{core_name}_unguarded_by_#{guard}#{extender}"

    line = __LINE__ + 1
    class_eval(
      "
      alias_method(#{unguarded_name.inspect}, #{method.to_sym.inspect})
      def #{method}(*args, &block)
        send(#{guard.to_sym.inspect}=, true)
        #{unguarded_name}(*args, &block)
      ensure
        send(#{guard.to_sym.inspect}=, false)
      end
    ",
      __FILE__,
      __LINE__ - 10
    )
  end
end

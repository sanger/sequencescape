module SampleManifestExcel
  # A dynamic option can be provided to a SampleManifestExcel::Range
  # in place of the usual options array.
  # It gets evaluated dynamically at manifest generation time,
  # allowing for columns that take their accepted values
  # from the database
  class DynamicOption
    include Enumerable

    attr_reader :klass, :scope, :identifier
    # Create a new dynamic otpion
    #
    # @param [Class] klass: The class on which the scope will be called
    # @param [Symbol] scope: A scope called on the class
    # CAUTION: Rails 3 returns an array for .all, not a scope.
    # This is resolved in rails 4. Until then :all will NOT work as a scope argument.
    # @param [Symbol] identifier: The attribute used to define the options range
    # @return [DynamicOption] description of returned object
    def initialize(klass:, scope:, identifier: :name)
      @klass = klass
      @scope = scope
      @identifier = identifier
    end

    def to_a
      klass.public_send(scope).pluck(identifier)
    end

    def empty?
      klass.public_send(scope).none?
    end

    delegate :each, :length, to: :to_a

  end
end

# frozen_string_literal: true

module SequencescapeExcel
  ##
  # A list will create a struct of objects.
  # Each attribute of the struct relates to an attribute of the object of a specific class.
  # Each attribute will be a Hash
  # This allows each object to be found by its various keys.
  # Each item in the hash will relate to the same object.
  # Any candidate which uses a List must respond to the valid? method.
  # Each key must relate to a unique field.
  # Example:
  #  class Racket
  #    attr_reader :weight, :balance, :cost
  #
  #    def initialize(weight, balance, cost)
  #     @weight, @height, @balance = weight, balance, cost
  #    end
  #
  #    def valid?
  #     weight.present? && height.present? && cost.present?
  #    end
  #  end
  #
  #  class RacketList
  #   include List
  #   list_for :racket, keys: [:weight, :balance]
  #  end
  #
  # racket_1 = Racket.new(130, "head heavy", 75)
  # racket_2 = Racket.new(120, "head light", 85)
  #
  # racket_list = RacketList.new
  # racket_list.add racket_1
  # racket_list.add racket_2
  #
  # racket_list.count => 2
  # racket_list.keys => [:weight, :balance]
  # racket_list.weights => ["130", "120"]
  # racket_list.balances => ["head heavy", "head light"]
  # racket_list.find_by(:weight, "130") => racket_1
  # racket_list.find_by(:balance, "head light") => racket_2
  # racket_list.reset!
  # racket_list.count => 0
  #
  module List
    extend ActiveSupport::Concern
    include Enumerable
    include Comparable

    included {}

    ##
    # ClassMethods
    module ClassMethods
      ##
      # Set up the list
      # It will:
      # - create a list of keys
      # - create a struct class based on the name
      # - creates a method which returns a list of keys for the items in each key
      # rubocop:todo Metrics/MethodLength
      def list_for(*args) # rubocop:todo Metrics/AbcSize
        options = args.extract_options!

        model = args.first.to_s.classify

        list_model = "#{model}Items"

        define_method :keys do
          @keys ||= options[:keys]
        end

        options[:keys].each do |key|
          define_method key.to_s.pluralize do
            items.fetch(key).keys
          end
        end

        alias_method args.first, :values

        return if const_defined?(list_model)

        list_model_const =
          Object.const_set(
            list_model,
            Struct.new(*options[:keys]) do
              def fetch(key)
                members.include?(key) ? self[key] : {}
              end
            end
          )

        define_method :list_model do
          list_model_const
        end
      end
      # rubocop:enable Metrics/MethodLength
    end

    def initialize
      yield self if block_given?
    end

    ##
    # relates to each value i.e. each object that is added.
    def each(&)
      values.each(&)
    end

    def values
      @values ||= []
    end

    # ##
    # # If the items don't exist then create a new struct with each key being
    # # an empty hash.
    def items
      @items ||= create_list
    end

    ##
    # Only add an item if it is valid
    # add the item to the list of values
    # add the item along with its attribute to each key
    def add(item)
      return unless item.valid?

      values << item
      keys.each { |key| items.fetch(key).store(item.send(key).to_s, item) }
    end

    ##
    # Uses dup
    # It is up to the list item class to decide on the parameters for dup
    def add_copy(item)
      add item.dup
    end

    ##
    # Find by key and attribute.
    # If it doesn't exist it won't blow up but will return nil
    def find_by(key, value)
      items.dig(key, value.to_s.squish)
    end

    def find(value)
      keys.each do |key|
        item = find_by(key, value)
        return item if item.present?
      end
      nil
    end

    ##
    # Empty the struct and start again. This is very destructive.
    def reset!
      @values = []
      @items = create_list
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      values <=> other.values
    end

    def inspect
      "<#{self.class}: @keys=#{keys}, @values=#{values.inspect}>"
    end

    private

    def create_list
      list_model.new(*keys.collect { |_k| {} })
    end
  end
end

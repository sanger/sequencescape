# frozen_string_literal: true
module Attributable
  class Association
    module Target
      def self.extended(base)
        base.class_eval do
          include InstanceMethods

          scope :for_selection, -> { order(:name) }
        end
      end

      def for_select_association
        for_selection.pluck(:name, :id)
      end

      def default
        nil
      end

      module InstanceMethods
        def for_select_dropdown
          [name, id]
        end
      end
    end

    attr_reader :name

    def initialize(owner, name, method, options = {})
      @owner = owner
      @name = name
      @method = method
      @required = options.delete(:required) || false
      @scope = Array(options.delete(:scope))
    end

    def required?
      @required
    end

    def optional?
      !required?
    end

    def assignable_attribute_name
      :"#{@name}_#{@method}"
    end

    def from(record)
      record.send(@name).try(@method)
    end

    def display_name
      Attribute.find_display_name(@owner, name)
    end

    def kind
      FieldInfo::SELECTION
    end

    def find_default(*_args)
      nil
    end

    def selection?
      true
    end

    def selection_options(_)
      scoped_selection.all.map(&@method.to_sym).sort
    end

    def to_field_info(*_args)
      FieldInfo.new(
        display_name: display_name,
        key: assignable_attribute_name,
        kind: kind,
        selection: selection_options(nil)
      )
    end

    def configure(target) # rubocop:todo Metrics/MethodLength
      target.class_eval(
        %{
        def #{assignable_attribute_name}=(value)
          record = self.class.reflections['#{@name}'].klass.find_by_#{@method}(value) or
            raise ActiveRecord::RecordNotFound, "Could not find #{@name} with #{@method} \#{value.inspect}"
          send(:#{@name}=, record)
        end

        def #{assignable_attribute_name}
          send(:#{@name}).send(:#{@method})
        end
      }
      )
    end

    private

    def scoped_selection
      @scope.inject(@owner.reflections[@name.to_s].klass) { |k, v| k.send(v.to_sym) }
    end
  end
end

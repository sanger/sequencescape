# frozen_string_literal: true

module Heron
  module Factories
    module Concerns
      #
      # This module adds validation and tools to manage factories that act as content in a receptacle
      # Eg: ::Heron::Factories::Sample
      #
      # **Requirements**
      # - The method or attribute *recipient_factory* needs to be defined with the class that act as
      #   factory for receptacles. Eg: ::Heron::Factories::Tube
      # - The content configuration should be already stored in @params
      # - The content configuration object needs to be in @params[recipients_key]
      # - The method or attribute recipients_key will need to identify the key where the config is
      #   stored. Eg: :tubes
      # - All keys referring to coordinates in the content configuration are considered as validated,
      #   if that is not the case, that validation can be provided by including the module
      #   Heron::Factories::Concerns::RecipientsCoordinate
      # - The class should include the module Heron::Factories:Concerns::CoordinatesSupport
      #
      # **Use**
      # Include the module in the class after checking the previous list of requirements.
      #
      # **Effect**
      # Factories for each recipient in each well will be generated.
      # Any validation error from them will be aggregated in the base object.
      #
      module Recipients
        def self.included(klass)
          klass.instance_eval { validate :check_recipients, if: :recipients }
        end

        def recipients
          return unless @params[recipients_key]
          return if errors.count.positive?

          @recipients ||=
            params_for_recipient.keys.index_with do |coordinate|
              recipient_factory.new(params_for_recipient[coordinate])
            end
        end

        def check_recipients
          return if errors.count.positive?

          recipients.each_key do |coordinate|
            recipient = recipients[coordinate]

            next if recipient.valid?

            recipient.errors.each { |error| errors.add("Recipient at #{coordinate} #{error.attribute}", error.message) }
          end
        end

        def params_for_recipient
          return unless @params[recipients_key]

          @params_for_recipient ||=
            @params[recipients_key]
              .keys
              .each_with_object({}) do |location, obj|
                obj[unpad_coordinate(location)] = @params.dig(recipients_key, location).except(:content)
              end
        end
      end
    end
  end
end

# frozen_string_literal: true

module StateChanger
  # Abstract class for StateChangers, should not be used directly
  # A state changer is designed to handle the transition of a piece of
  # {Labware} from one state to another. Typically this involved:
  # - Updating the transfer request into and out of the {Receptacle receptacles}
  # - Potentially failing the associated {Request requests}
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes

    # The labware to update the state of
    # @return [Labware] The labware to update the state of
    attr_accessor :labware
    # The user performing the action that led to the state change
    # @return [User] The user performing the action that led to the state change
    attr_accessor :user

    #  @!attribute rw target_state
    #    @return [String] String representing the state to transition to
    attribute :target_state, :string
    #  @!attribute rw contents
    #    @return [nil, Array<String>] Array of well locations to update, leave nil or empty for ALL wells
    attribute :contents, default: nil
    #  @!attribute rw customer_accepts_responsibility
    #    @return  [Boolean] The customer proceeded against advice and will still
    #                       be charged in the the event of a failure
    attribute :customer_accepts_responsibility, :boolean, default: false

    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
    # relate to all wells of the plate, otherwise only the selected ones are updated.
    # @return [Void]
    def update_labware_state
      raise NotImplementedError
    end
  end
end

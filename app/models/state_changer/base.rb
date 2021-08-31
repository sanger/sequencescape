# frozen_string_literal: true

module StateChanger
  # Abstract class for StateChangers, should not be used directly
  # A state changer is designed to handle the transition of a piece of
  # {Labware} from one state to another. Typically this involved:
  # - Updating the transfer request into and out of the {Receptacle receptacles}
  # - Potentially failing the associated {Request requests}
  # @note This initial StateChanger classes have been derived from the
  #       behaviour originally in the corresponding PlatePurpose. This
  #       has built up organically over time, and I (JG) don't believe
  #       we actually depend on a lot of the differences in behaviour.
  #
  # Usage as of 2021-03-21
  # Class                            Used   Last used
  # StateChanger::MxTube             43758  2021-03-23
  # StateChanger::StandardPlate      121793 2021-03-23
  # StateChanger::InputPlate         14     2021-03-02
  # StateChanger::InitialStockTube   30823  2021-03-23
  # StateChanger::StockTube          5650   2021-03-11
  # StateChanger::QcableLibraryPlate 213    2018-08-16
  # StateChanger::QcableLabware      3020   2021-03-21
  # StateChanger::StockMxTube        111    2018-08-20 # Removed
  #
  # @abstract This class should not be used directly
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes

    # Maps the {#target_state} of the {StateChanger} to the target state of
    # the associated requests. By default, StateChangers will not transition outer
    # requests if the result of this mapping is nil.
    # @return [Hash<String,String>] Hash indexed by target state, mapping to the
    #                               desired transition of outer requests.
    class_attribute :map_target_state_to_associated_request_state
    self.map_target_state_to_associated_request_state = {}

    # The labware to update the state of
    # @return [Labware] The labware to update the state of
    attr_accessor :labware

    # The user performing the action that led to the state change
    # @return [User] The user performing the action that led to the state change
    attr_accessor :user

    # @return [String] String representing the state to transition to
    attribute :target_state, :string

    # @return [nil, Array<String>] Array of well locations to update, leave nil or empty for ALL wells
    attribute :contents, default: nil

    # @return  [Boolean] The customer proceeded against advice and will still
    #                    be charged in the the event of a failure
    attribute :customer_accepts_responsibility, :boolean, default: false

    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.  If {#contents} is blank then the change is assumed
    # to relate to all wells of the plate, otherwise only the selected ones are updated.
    # @return [Void]
    def update_labware_state
      raise NotImplementedError
    end

    # Returns the state to transition associated requests to. If this returns nil
    # the state changer should not transition the outer requests
    def associated_request_target_state
      map_target_state_to_associated_request_state[target_state]
    end
  end
end

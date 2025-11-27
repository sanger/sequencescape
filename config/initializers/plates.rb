# frozen_string_literal: true

Rails.application.configure do
  config.cherrypickable_default_type = 'ABgene_0800'
  config.plate_default_type = 'ABgene_0800'
  config.plate_default_max_volume = 180

  # See issue #3134 Leave wells D3/H10 free
  config.plate_default_control_wells_to_leave_free = [19, 79].freeze
end

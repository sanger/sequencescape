# frozen_string_literal: true

class UltimaApplication < ApplicationRecord
  belongs_to :ug100_configuration, class_name: 'UltimaConfiguration'
  belongs_to :ug200_configuration, class_name: 'UltimaConfiguration'

  belongs_to :uga_primer, class_name: 'UltimaPrimer'
  belongs_to :ugb_primer, class_name: 'UltimaPrimer'

  delegate :application_preset, to: :ug100_configuration, prefix: true
  delegate :application_preset, to: :ug200_configuration, prefix: true
  delegate :application_type, to: :ug100_configuration, prefix: true
  delegate :application_type, to: :ug200_configuration, prefix: true

  delegate :name, to: :uga_primer, prefix: true
  delegate :name, to: :ugb_primer, prefix: true
end

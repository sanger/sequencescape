# frozen_string_literal: true

class UltimaApplication < ApplicationRecord
  belongs_to :ug100_preset, class_name: 'UltimaPreset'
  belongs_to :ug200_preset, class_name: 'UltimaPreset'

  belongs_to :uga_primer, class_name: 'UltimaPrimer'
  belongs_to :ugb_primer, class_name: 'UltimaPrimer'
end

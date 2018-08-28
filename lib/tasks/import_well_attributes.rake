# frozen_string_literal: true

namespace :import do
  desc 'Import well attributes into qc results'
  task well_attributes: [:environment] do
    # Due to be run on or around 21/08/2018 can be removed afterwards
    require './lib/import_well_attributes'
    ImportWellAttributes.import
  end
end

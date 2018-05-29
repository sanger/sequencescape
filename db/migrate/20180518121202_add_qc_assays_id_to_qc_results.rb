# frozen_string_literal: true

# A QcAssay groups together results which were made at the same time
# it allows us to tie together coupled results, such as
# loci_tested and loci_passed
class AddQcAssaysIdToQcResults < ActiveRecord::Migration[5.1]
  def change
    add_reference :qc_results, :qc_assay, foreign_key: true
  end
end

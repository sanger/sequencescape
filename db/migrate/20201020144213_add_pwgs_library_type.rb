# frozen_string_literal: true
# Add the pWGS-384 library type and join to compatible request types
class AddPwgsLibraryType < ActiveRecord::Migration[5.2]
  def self.up
    ActiveRecord::Base.transaction do |_t|
      lt = LibraryType.find_or_create_by!(name: 'pWGS-384')
      RequestType.find_by(key: 'illumina_b_hiseq_x_paired_end_sequencing').library_types << lt
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |_t|
      lts = RequestType.find_by(key: 'illumina_b_hiseq_x_paired_end_sequencing').library_types
      lts.find_by(name: 'pWGS-384').destroy!
    end
  end
end

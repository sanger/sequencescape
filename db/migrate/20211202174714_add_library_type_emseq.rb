#
# Add new library type emSEQ for bespoke pcr submission templates
#
class AddLibraryTypeEmseq < ActiveRecord::Migration[6.0]
  def self.request_types
    %w[limber_chromium_bespoke limber_pcr_bespoke].map { |rt_key| RequestType.find_by(key: rt_key) }
  end

  def self.up
    ActiveRecord::Base.transaction do |_t|
      lt = LibraryType.find_or_create_by!(name: 'emSEQ')
      self.request_types.each { |rt| rt.library_types << lt }
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |_t|
      self.request_types.each do |rt|
        lts = rt.library_types
        lts.find_by(name: 'emSEQ').destroy!
      end
    end
  end
end

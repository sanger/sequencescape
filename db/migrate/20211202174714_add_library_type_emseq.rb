#
# Add new library type emSEQ for bespoke pcr submission templates
#
class AddLibraryTypeEmseq < ActiveRecord::Migration[6.0]
  def self.REQUEST_TYPES
    %w[limber_chromium_bespoke limber_pcr_bespoke].map { |rt_key| RequestType.find_by(key: rt_key) }
  end
  def self.up
    ActiveRecord::Base.transaction do |_t|
      lt = LibraryType.find_or_create_by!(name: 'emSEQ')
      self.REQUEST_TYPES.each { |rt| rt.library_types << lt }
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |_t|
      self.REQUEST_TYPES.each do |rt|
        lts = rt.library_types
        lts.find_by(name: 'emSEQ').destroy!
      end
    end
  end
end

class FixSpikedInBufferAgain < ActiveRecord::Migration
  def self.up
    # Some aliquots that have come via the spiked buffers do not have libraries on them.  The easiest
    # way to solve this is to walk back up the asset graph for each aliquot receptacle to find an
    # aliquot that has and use that.  If that fails we can resort to the first library that we find
    # and use that as the library.
    ActiveRecord::Base.transaction do
      SpikedBuffer.phiX_sample.aliquots.select do |aliquot|
        aliquot.library.nil?  # Finds the aliquots missing the library
      end.each do |aliquot_missing_library|
        catch(:library_set_ok) {
          # Walk back up the assets until we find one that has an aliquot that matches the spiked
          # buffer aliquot, and has a library.
          assets_to_walk = [ aliquot_missing_library.receptacle ]
          until assets_to_walk.empty?
            asset            = assets_to_walk.shift
            matching_aliquot = asset.aliquots.detect { |x| (aliquot_missing_library =~ x) && x.library.present? }
            if matching_aliquot.nil?
              assets_to_walk.concat(asset.parents)
              next
            end

            # The aliquot has been found, update the broken one and move on to the next.
            aliquot_missing_library.update_attributes!(:library => matching_aliquot.library)
            throw :library_set_ok
          end

          # We've completely failed to find the library for this aliquot!  Yes, we could have looked
          # for the library and fixed that but actually we have no such cases in production, and if
          # we do by the time this migration is executed then we have a bigger issue to deal with.
          raise StandardError, "Could not find library asset for aliquot #{aliquot_missing_library.id}"
        }
      end
    end
  end

  def self.down
    # Nothing to do on the down.
  end
end

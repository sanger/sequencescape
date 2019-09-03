# frozen_string_literal: true

# The transfer_request_type_id is not required any more
# When the schema.rb was refreshed from the production schema it revealed a
# not  null constraint on this column, which was preventing seeding without
# populating the column with arbitrary ids. This migration removes the column
# entirely.
#
# As an added note, plate_purpose_relationships are solely the domain of
# Generic Lims, which has now been replaced by Limber. Once it has been
# completely shut down, this behaviour can be safely stripped out.
class DropTransferRequestTypeIdFromPlatePurposeRelationships < ActiveRecord::Migration[5.1]
  def change
    remove_column :plate_purpose_relationships, :transfer_request_type_id, :integer, null: false
  end
end

class ChangeCreateAssetRequestsStateToPassed < ActiveRecord::Migration
  def self.up
    Request.update_all(
      'state="passed"',
      [ 'request_type_id=?', RequestType.find_by_key('create_asset').id ]
    )
  end

  def self.down
    # Nothing really needed here
  end
end

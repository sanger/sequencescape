module Plate::Iterations

    def iteration
    return nil if parent.nil?  # No parent means no iteration, not a 0 iteration.

    # NOTE: This is how to do row numbering with MySQL!  It essentially joins the assets and asset_links
    # tables to find all of the child plates of our parent that have the same plate purpose, numbering
    # those rows to give the iteration number for each plate.
    iteration_of_plate = connection.select_one(%Q{
      SELECT iteration
      FROM (
        SELECT iteration_plates.id, @rownum:=@rownum+1 AS iteration
        FROM (
          SELECT assets.id
          FROM asset_links
          JOIN assets ON asset_links.descendant_id=assets.id
          WHERE asset_links.direct=TRUE AND ancestor_id=#{parent.id} AND assets.sti_type in (#{Plate.derived_classes.map(&:inspect).join(',')}) AND assets.plate_purpose_id=#{plate_purpose.id}
          ORDER by assets.created_at ASC
        ) AS iteration_plates,
        (SELECT @rownum:=0) AS r
      ) AS a
      WHERE a.id=#{self.id}
    }, "Plate #{self.id} iteration query")

    iteration_of_plate['iteration'].to_i
  end


end

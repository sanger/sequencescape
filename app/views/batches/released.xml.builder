# frozen_string_literal: true
xml.instruct!
xml.batches do |batches|
  @batches.each do |b|
    batches.batch do |batch|
      batch.id b.id
      batch.lanes do |lanes|
        count = 0
        b.items.ordered.each do |item|
          count = count + 1
          lanes.lane('position' => count) do |lane|
            if item.resource?
              lane.control('id' => item.ident, 'name' => item.name, 'request_id' => item.request)
            else
              lane.sample('id' => item.ident, 'name' => item.name, 'request_id' => item.request)
            end
          end
        end
      end
    end
  end
end

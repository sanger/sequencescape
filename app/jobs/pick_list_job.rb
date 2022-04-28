# frozen_string_literal: true
# Triggers the building of the submission
PickListJob =
  Struct.new(:pick_list_id) do
    def perform
      PickList.find(pick_list_id).process_immediately
    end
  end

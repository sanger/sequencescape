xml.instruct!
xml.SUBMISSION({center_name: @submission[:center_name], broker_name: @submission[:broker], alias: @submission[:submission_id], submission_date: @submission[:submission_date], 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'}) do |submission|
  submission.CONTACTS do |contacts|
    contacts.CONTACT({inform_on_error: @submission[:contact_inform_on_error], inform_on_status: @submission[:contact_inform_on_status],name: @submission[:name]})
  end
  submission.ACTIONS do |actions|
    actions.ACTION do |action|
      if @accession_number.blank?
        action.ADD({source: @submission[:source], schema: @submission[:schema]})
      else
        action.MODIFY({source: @submission[:source], target: ""})
      end
    end
    actions.ACTION do |action2|
      if @submission[:hold] == "protect"
        action2.PROTECT
      else
        action2.HOLD
      end
    end
  end
end


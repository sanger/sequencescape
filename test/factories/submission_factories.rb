Factory.define :submission__ do |submission|
  #raise "call Factory::submission instead "
end

Factory.define :submission_without_order , :class => Submission do |submission|
    submission.user                  {|user| user.association(:user)}
end

class Factory
  def self.submission(options)
    submission_options = {}
    [:message, :state].each do |option|
      value = options.delete(option)
      submission_options[option] = value if value
    end
    state = options.delete(:state)
    message = options.delete(:message)
    submission = Factory(:order_with_submission, options).submission
    #trying to skip StateMachine
    if submission_options.present?
      submission.update_attributes!(submission_options)
    end
    submission.reload
  end
end


#TODO move in a separate file
#easier to keep it here at the moment because we are moving stuff between both
Factory.define :order do |order|
    order.study                 {|study| study.association(:study)}
    order.workflow              {|workflow| workflow.association(:submission_workflow)}
    order.project               {|project| project.association(:project)}
    order.user                  {|user| user.association(:user)}
    order.item_options          {}
    order.request_options       {}
    order.assets                []
    order.request_types         { [ Factory(:request_type).id ] }
end


Factory.define :order_with_submission, :parent => :order do |order|
  order.after_build { |o| o.create_submission(:user_id => o.user_id) }
end


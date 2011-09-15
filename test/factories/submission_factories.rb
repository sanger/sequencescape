Factory.define :submission do |submission|
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


Factory.define :submission do |submission|
    submission.workflow              {|workflow| workflow.association(:submission_workflow)}
    submission.study                 {|study| study.association(:study)}
    submission.project               {|project| project.association(:project)}
    submission.user                  {|user| user.association(:user)}
    submission.item_options          {}
    submission.request_options       {}
    submission.assets                []
    submission.request_types         { [ Factory(:request_type).id ] }
end


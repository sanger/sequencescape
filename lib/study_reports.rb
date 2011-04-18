Study.find_each do |study|
  study_report = StudyReport.create!(:study => study)
  # delayed job
  study_report.perform
end



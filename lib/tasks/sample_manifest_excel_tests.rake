namespace :sample_manifest_excel do
  desc "Run all of the sample manifest excel tests"
  task :tests do
   Dir.glob(File.join(Rails.root,"test","lib","sample_manifest_excel","**","*_test.rb")).each do |file|
    system("bundle exec ruby -Itest #{file}")
   end
  end
end
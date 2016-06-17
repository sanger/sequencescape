require "rake/testtask"

namespace :label_printer do
  desc "Run all label printer tests"
  task :tests do
    Rake::TestTask.new(:all_tests) do |t|
    	t.libs << "test"
      t.pattern = File.join(Rails.root,"test","lib","label_printer","**","*_test.rb")
      t.test_files = FileList['test/unit/plate_creator_test.rb',
      												'test/functional/sample_manifests_controller_test.rb',
      												'test/functional/batches_controller_test.rb',
      												'test/unit/sanger_barcode_test.rb']
    end
    Rake::Task["all_tests"].execute
  end
end

namespace :test do
  namespace :aggregate do
    desc 'Delete aggregate coverage data.'
    task(:clean) { rm_rf 'coverage.data coverage/aggregated' }
    desc 'Setup paramater so rcov will use aggregate coverage data'
    # TODO: move the gem filter in another task
    task(:on) { ENV['RCOV_PARAMS'] = '--aggregate coverage.data --sort coverage -x \"gems,osx\" -o "coverage/aggregated" ' }
  end

  desc 'Run one Rcov report for the all files of the project'
  task rcov: ['test:aggregate:clean', 'test:aggregate:on', 'test:units:rcov', 'test:functionals:rcov']
end

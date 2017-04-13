### Thresholds for s:
# SEE-ALSO: #{Rails.root}/config/analytics/roodi.yml
FLOG_COMPLEXITY_THRESHOLD = 60
FLAY_DUPLICATION_THRESHOLD = 200

namespace :test do
  desc 'Run all static code analysis tasks'
  task analytics: ['test:analytics:flay', 'test:analytics:roodi', 'test:analytics:roodi_strict']
  namespace :analytics do
    task :load_rails_env do
      require 'config/environment'
    end
    desc 'Analyze for code complexity'
    task flog: :load_rails_env do
      require 'flog'
      WHITELIST = YAML.load(File.read("#{Rails.root}/config/analytics/flog_whitelist.yml"))
      # puts WHITELIST.inspect

      print 'Complexity...'
      STDOUT.flush
      flog = Flog.new

      flog.flog('app')

      bad_methods = flog.totals.select do |name, score|
        if !WHITELIST[name].nil?
          score > WHITELIST[name]
        else
          score > FLOG_COMPLEXITY_THRESHOLD
        end
      end
      bad_methods.sort { |a, b| a[1] <=> b[1] }.each do |name, score|
        puts '%s: %d' % [name, score + 1]
      end
      raise "#{bad_methods.size} methods have a flog complexity > #{FLOG_COMPLEXITY_THRESHOLD}" unless bad_methods.empty?
      puts 'OK'
    end

    desc 'Analyze for code duplication'
    task flay: :load_rails_env do
      require 'flay'
      print 'Duplication...'
      STDOUT.flush
      flay = Flay.new(fuzzy: false, verbose: false, mass: (FLAY_DUPLICATION_THRESHOLD + 1))

      files = Flay.expand_dirs_to_files(['app'])
      exclude_files = YAML.load(File.read("#{Rails.root}/config/analytics/flay_whitelist.yml"))
      check_files = files - exclude_files
      # puts files.join("\n")
      flay.process(*check_files.uniq)

      if flay.masses.empty?
        puts 'OK'
      else
        flay.report
        raise "#{flay.masses.size} chunks of code have a duplicate mass > #{FLAY_DUPLICATION_THRESHOLD}"
      end
    end

    desc 'Analyze for code design issues'
    task roodi: :load_rails_env do |_t|
      require 'roodi'
      require 'roodi_task'
      print 'Design...'
      old_files = YAML.load(File.read("#{Rails.root}/config/analytics/roodi_whitelist.yml"))
      STDOUT.flush
      RoodiTask.new '#{t}:run', old_files, 'config/analytics/roodi.yml'
      Rake::Task['#{t}:run'].invoke
      puts 'OK'
    end

    desc 'Analyze for code design issues'
    task roodi_strict: :load_rails_env do |_t|
      require 'roodi'
      require 'roodi_task'
      print 'Design (new things)...'
      old_files = YAML.load(File.read("#{Rails.root}/config/analytics/roodi_whitelist.yml"))
      files = Dir.glob('app/**/*.rb') - old_files
      #    puts files.inspect
      STDOUT.flush
      RoodiTask.new '#{t2}:run', files, 'config/analytics/roodi_new.yml'
      Rake::Task['#{t2}:run'].invoke
      puts 'OK'
    end
    desc 'Show warnings from the Ruby interpreter'
    task :warnings do |_t|
      warnings = []
      # RUBYOPT added by Bundler causes significant startup cost, so we empty it
      super_find_cmd = '(RUBYOPT="" find . \( -not -path "*generators*" -not -path "*templates*" \)' +
                       ' -and \( -name "*.rb" -or -name "*.rake" \)' +
                       ' -exec ruby -c {} \; ) 2>&1'
      pipe = IO.popen(super_find_cmd.to_s)
      pipe.each do |line| # From the perspective of the new pseudo terminal
        if line !~ /Syntax OK/
          putc 'W'
          warnings << line
        else
          putc '.'
        end
        STDOUT.flush
      end
      puts
      raise warnings.to_s unless warnings.none?
    end
  end
end

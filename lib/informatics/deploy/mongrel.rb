namespace :deploy do
  namespace :mongrel do
    task :start, roles: :app do
      run "mongrel_rails mongrel::start -C #{shared_path}/config/server.yml -c #{current_path}"
    end

    task :restart, roles: :app do
      run "mongrel_rails mongrel::restart -c #{current_path}"
    end

    task :stop, roles: :app do
      run "mongrel_rails mongrel::stop -c #{current_path}"
    end
  end

  namespace :cluster do
    task :start, roles: :app do
      run "mongrel_rails cluster::start -C #{shared_path}/config/server.yml"
    end

    task :restart, roles: :app do
      run "mongrel_rails cluster::restart -C #{shared_path}/config/server.yml"
    end

    task :stop, roles: :app do
      run "mongrel_rails cluster::stop -C #{shared_path}/config/server.yml"
    end
  end

  # TODO: - staging hardcoded in path for LogRotate, intended?
  namespace :logrotate_tasks do
    task :force, roles: :app do
      run "/usr/sbin/logrotate -f -s /software/webapp/staging/logrotate.status #{shared_path}/config/logrotate.conf"
    end
  end

  desc 'Disable requests to the app, show maintenance page'
  task :disable_web, roles: :app do
    run "cp #{current_path}/public/maintenance.html  #{shared_path}/system/maintenance.html"
  end

  desc 'Re-enable the web server by deleting any maintenance file'
  task :enable_web, roles: :app do
    run "rm #{shared_path}/system/maintenance.html"
  end

  desc 'Custom restart task for mongrel cluster'
  task :restart, roles: :app, except: { no_release: true } do
    deploy.cluster.restart
  end

  desc 'Custom start task for mongrel cluster'
  task :start, roles: :app do
    deploy.cluster.start
  end

  desc 'Custom stop task for mongrel cluster'
  task :stop, roles: :app do
    deploy.cluster.stop
  end

  desc 'Force rotation of logfiles'
  task :logrotate, roles: :app do
    deploy.logrotate_tasks.force
  end
end

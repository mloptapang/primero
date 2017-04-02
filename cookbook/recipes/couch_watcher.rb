couch_watcher_log_dir = ::File.join(node[:primero][:log_dir], 'couch_watcher')
directory couch_watcher_log_dir do
  action :create
  mode '0755'
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
end

[::File.join(node[:primero][:app_dir], 'tmp/couch_watcher_history.json'),
 ::File.join(node[:primero][:app_dir], 'tmp/couch_watcher_restart.txt'),
 ::File.join(node[:primero][:log_dir], 'couch_watcher/production.log')
].each do |f|
  file f do
    #content ''
    #NOTE: couch_watcher_restart.txt must be 0666 to allow any user importing a config bundle
    #      to be able to touch the file, triggering a restart of couch_watcher
    #TODO: This is a hack, and probably no longer needed now that couch_watcher and passenger
    #      run as 'primero'
    mode '0666'
    owner node[:primero][:app_user]
    group node[:primero][:app_group]
    #action :create_if_missing
  end
end

couchwatcher_worker_file = "#{node[:primero][:daemons_dir]}/couch-watcher-worker.sh"
file couchwatcher_worker_file do
  mode '0755'
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
  content <<-EOH
#!/bin/bash
#Launch the Couch Watcher
#This file is generated by Chef
cd #{node[:primero][:app_dir]}
source #{::File.join(node[:primero][:home_dir],'.rvm','scripts','rvm')}
export PASSENGER_TEMP_DIR=<%= node[:primero][:app_dir] %>/tmp
RAILS_ENV=#{node[:primero][:rails_env]} RAILS_LOG_PATH=#{couch_watcher_log_dir} bundle exec rails r lib/couch_changes/base.rb
EOH
end

supervisor_service 'couch-watcher' do
  command couchwatcher_worker_file
  autostart true
  autorestart true
  user node[:primero][:app_user]
  directory node[:primero][:app_dir]
  numprocs 1
  killasgroup true
  stopasgroup true
  redirect_stderr true
  stdout_logfile ::File.join(couch_watcher_log_dir, '/output.log')
  stdout_logfile_maxbytes '20MB'
  stdout_logfile_backups 0
  # We want to stop the watcher before doing seeds/migrations so that it
  # doesn't go crazy with all the updates.  Make sure that everything that it
  # does is also done in this recipe (e.g. reindex solr, reset memoization,
  # etc..)
  action [:enable, :stop]
end

who_watches_worker_file = "#{node[:primero][:daemons_dir]}/who-watches-the-couch-watcher.sh"

file who_watches_worker_file do
  mode '0755'
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
  content <<-EOH
#!/bin/bash
#Look for any changes to /tmp/couch_watcher_restart.txt.
#When a change occurrs to that file, restart couch-watcher
inotifywait #{::File.join(node[:primero][:app_dir], 'tmp')}/couch_watcher_restart.txt && supervisorctl restart couch-watcher
EOH
end

supervisor_service 'who-watches-the-couch-watcher' do
  command who_watches_worker_file
  autostart true
  autorestart true
  user node[:primero][:app_user]
  directory node[:primero][:app_dir]
  numprocs 1
  killasgroup true
  stopasgroup true
  redirect_stderr true
  stdout_logfile ::File.join(node[:primero][:log_dir], 'couch_watcher/restart.log')
  stdout_logfile_maxbytes '20MB'
  stdout_logfile_backups 0
  # We want to stop the watcher before doing seeds/migrations so that it
  # doesn't go crazy with all the updates.  Make sure that everything that it
  # does is also done in this recipe (e.g. reindex solr, reset memoization,
  # etc..)
  action [:enable, :stop]
end
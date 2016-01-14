require 'bundler/capistrano'
require 'capistrano/sidekiq'
require 'rvm/capistrano'
require 'capistrano-unicorn'

default_run_options[:pty] = true

set :rvm_ruby_string, 'ruby-2.3.0'
set :rvm_type, :user
set :application, 'ruby-china'
set :repository,  'git://github.com/yinsigan/ruby-china.git'
set :branch, 'master'
set :scm, :git
set :user, 'hfpp2012'
set :deploy_to, "/home/hfpp2012/#{application}"
set :runner, 'hfpp2012'
# set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"
set :bundle_flags, ''

role :web, '115.28.165.211'
role :app, '115.28.165.211'
role :db,  '115.28.165.211', primary: true
role :queue, '115.28.165.211'

task :link_shared, roles: :web do
  run "mkdir -p #{shared_path}/log"
  run "mkdir -p #{shared_path}/pids"
  run "mkdir -p #{shared_path}/assets"
  run "mkdir -p #{shared_path}/system"
  run "mkdir -p #{shared_path}/cache"
  run "ln -sf #{shared_path}/system #{current_path}/public/system"
  run "ln -sf #{shared_path}/assets #{current_path}/public/assets"
  run "ln -sf #{shared_path}/config/*.yml #{current_path}/config/"
  run "ln -sf #{shared_path}/config/initializers/secret_token.rb #{current_path}/config/initializers"
  run "ln -sf #{shared_path}/pids #{current_path}/tmp/"
  run "ln -sf #{shared_path}/cache #{current_path}/tmp/"
end

task :compile_assets, roles: :web do
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:cdn"
end

task :migrate_db, roles: :web do
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake db:migrate"
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake db:mongoid:create_indexes"
end

after 'deploy:finalize_update', 'deploy:symlink', :link_shared#, :migrate_db, :compile_assets
after 'deploy:restart', 'unicorn:restart'
after 'deploy:start', 'unicorn:start'
after 'deploy:stop', 'unicorn:stop'

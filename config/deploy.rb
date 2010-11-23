set :environment, (ENV['target'] || 'staging')

set :user, 'staffers'
set :application, user
set :deploy_to, "/projects/#{user}/"
set :local_bin, "/projects/#{user}/.gem/ruby/1.8/bin/"

set :sock, "#{user}.sock"

# if environment == 'production' # production api box
#   set :domain, 'staffers.sunlightfoundation.com'
# else # environment == 'staging'
  set :domain, 'staffers.sunlightlabs.com'
# end

set :scm, :git
set :repository, "git@github.com:sunlightlabs/staffers.git"
set :branch, 'master'

set :deploy_via, :remote_cache
set :runner, user
set :admin_runner, runner

role :app, domain
role :web, domain

set :use_sudo, false
after "deploy", "deploy:cleanup"
after "deploy:update_code", "deploy:shared_links"
after "deploy:update_code", "deploy:bundle_install"

namespace :staffers do
  desc "Load/reload all data from CSVs - wipes database"
  task :reload do
    run "cd #{current_path} && rake load:all"
  end
end

namespace :deploy do
  task :start do
    run "cd #{current_path} && #{local_bin}/unicorn -D -l #{shared_path}/#{sock}"
  end
  
  task :stop do
    run "killall unicorn"
  end
  
  task :migrate do; end
  
  desc "Restart the server"
  task :restart, :roles => :app, :except => {:no_release => true} do
    run "killall -HUP unicorn"
  end
  
  desc "Run bundle install --local"
  task :bundle_install, :roles => :app, :except => {:no_release => true} do
    run "cd #{release_path} && #{local_bin}/bundle install --local"
  end
  
  desc "Get shared files into position"
  task :shared_links, :roles => [:web, :app] do
    run "ln -nfs #{shared_path}/config.yml #{release_path}/config/config.yml"
    run "ln -nfs #{shared_path}/config.ru #{release_path}/config.ru"
    run "ln -nfs #{shared_path}/csv #{release_path}/data/csv"
    run "rm -rf #{File.join release_path, 'tmp'}"
    run "rm #{File.join release_path, 'public', 'system'}"
    run "rm #{File.join release_path, 'log'}"
  end
end
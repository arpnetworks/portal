# config valid for current version and patch releases of Capistrano
lock "~> 3.10"

set :application, "portal"
set :repo_url, "git@github.com:arpnetworks/portal.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

set :assets_manifests, ['app/assets/config/manifest.js']

@deploy = YAML.load(File.read(File.join(File.dirname(__FILE__), 'arp', 'deploy.yml')))

# Default value for :linked_files is []
append :linked_files, "config/database.yml",
                      "config/master.key",
                      "config/arp/globals.yml",
                      "config/arp/password_encryption.yml",
                      "config/arp/tender.yml",
                      "config/arp/redis.yml",
                      "config/arp/hosts.yml",
                      "config/arp/iso-files.txt",
                      @deploy['configs']['billing']['gateway'],
                      @deploy['configs']['billing']['gpg'],
                      @deploy['configs']['billing']['paypal_key']

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
append :linked_dirs, "log",
                     "tmp/pids",
                     "tmp/cache",
                     "tmp/sockets",
                     "public/system",
                     ".bundle",
                     "vm-base" # For VM auto-provisioning

# Default value for default_env is {}
set :default_env, { path: "/home/garry/sys/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5
set :keep_assets, 5

# Uncomment the following to require manually verifying the host key before first deploy.
set :ssh_options, verify_host_key: :always

# rbenv
set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

# Defaults to [:web]
set :assets_roles, [:app]
set :maintenance_roles, -> { roles([:app])  }

set :maintenance_template_path, File.expand_path("../../app/assets/maintenance.html.erb", __FILE__)

namespace :deploy do
  desc 'Copy stragglers'
  task :copy_stragglers do
    stragglers = @deploy['configs']['stragglers']

    stragglers.each do |straggler|
      on roles(:app) do
        upload! straggler, "#{release_path}/#{straggler}"
      end
    end
  end

  before 'deploy:assets:precompile', :copy_stragglers

  namespace :puma do
    desc 'Restart puma'
    task :restart do
      on roles(:app) do
        within(release_path) do
          execute :bundle, :exec, 'pumactl', '-P', "#{release_path}/tmp/pids/server.pid", "restart"
        end
      end
    end
  end

  namespace :sidekiq do
    desc 'Restart Sidekiq'
    task :restart do
      on roles(:app) do
        within(release_path) do
          execute :sudo, :restart, 'portal-staging-sidekiq'
        end
      end
    end
  end

  after 'deploy:symlink:release', 'puma:restart'
  after 'puma:restart', 'sidekiq:restart'
end

desc "Backup (mysqldump) production databases and rsync to local box"
task :backup do
  on @deploy['configs']['backup_host'] do |host|
    [['production', 'arp_customer_cp'], ['powerdns_production', 'powerdns']].each do |stuff|
      conf_entry = stuff[0]
      database   = stuff[1]

      unless ENV['DIFF']
        filenamep = "#{database}-production.dump.#{Time.now.to_f}.sql.bz2"
        filename  = "/tmp/#{filenamep}"
      else
        filenamep = "#{database}-production.dump.#{Time.now.to_f}-to-diff.sql"
        filename  = "/tmp/#{filenamep}"
      end
      text = capture "cat /var/www/portal/current/config/database.yml"
      yaml = YAML::load(text)
      conf = yaml[conf_entry]

      if ENV['DIFF']
        if conf['database'] == 'arp_customer_cp'
          @additional_args = '--skip-extended-insert --skip-quick --no-create-info'
          execute("mysqldump -u #{conf['username']} -p -h #{conf['host']} #{conf['database']} --ignore-table=#{conf['database']}.sessions #{@additional_args} > #{filename}", interaction_handler: {
            'Enter password: ' => conf['password'] + "\n"
          })
        end
      else
        execute("mysqldump -u #{conf['username']} -p -h #{conf['host']} #{conf['database']} --ignore-table=#{conf['database']}.sessions | bzip2 -c > #{filename}", interaction_handler: {
          'Enter password: ' => conf['password'] + "\n"
        })
      end

      `mkdir -p #{File.dirname(__FILE__)}/../backups`
      unless ENV['DIFF'] && conf['database'] != 'arp_customer_cp'
        download! filename, filenamep
        `mv #{filenamep} #{File.dirname(__FILE__)}/../backups`
        execute "rm -f #{filename}"
      end

      if ENV['LOAD']
        yaml = YAML::load_file('config/database.yml')
        conf = yaml[conf_entry.sub('production', 'development')]
        filename.gsub!("/tmp", "./backups")
        if conf['adapter'] == 'mysql2'
          mysql = `which mysql mysql5`.split("\n")
          if mysql && mysql[0]
            if conf['database'] !~ /powerdns/
              puts "Saving exports table"
              `mysqldump -u #{conf['username']} -h #{conf['host'] || '127.0.0.1'} -p #{conf['database']} --no-create-info --tables exports > /tmp/exports.sql`
            end
            puts "Loading data from #{filename} into *local* development DB"
            puts "Executing `bunzip2 -c #{filename} | #{mysql[0]} -u #{conf['username']} -h #{conf['host'] || '127.0.0.1'} -p #{conf['database']}`"
            `bunzip2 -c #{filename} | #{mysql[0]} -u #{conf['username']} -h #{conf['host'] || '127.0.0.1'} -p #{conf['database']}`
            if conf['database'] !~ /powerdns/
              puts "Restoring exports table"
              `cat /tmp/exports.sql | #{mysql[0]} -u #{conf['username']} -h #{conf['host'] || '127.0.0.1'} -p #{conf['database']}`
            end
          end
        end
      end

      if ENV['DIFF']
        diffs = Dir['backups/*to-diff.sql'].sort
        last, current = diffs[-2..-1]
        puts ""
        puts "Check 'em out!!"
        puts ""
        puts "vimdiff #{last} #{current}"
      end
    end
  end
end

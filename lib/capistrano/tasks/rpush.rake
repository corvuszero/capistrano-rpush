git_plugin = self

namespace :rpush do
  desc 'Check if config file exists'
  task :check do
    on roles (fetch(:rpush_role)) do |role|
      unless  test "[ -f #{fetch(:rpush_conf)} ]"
        warn 'rpush.rb NOT FOUND!'
        info 'Configure rpush for your project before attempting a deployment.'
      end
    end
  end

  desc 'Restart rpush'
  task :restart do
    on roles (fetch(:rpush_role)) do |role|
      git_plugin.rpush_switch_user(role) do
        git_plugin.each_process_with_index(reverse: true) do |pid_file, index|
          if git_plugin.pid_file_exists?(pid_file) && git_plugin.process_exists?(pid_file)
            git_plugin.stop_rpush(pid_file)
          end
        end
        git_plugin.start_rpush(pid_file)
      end
    end
  end

  desc 'Start rpush'
  task :start do
    on roles (fetch(:rpush_role)) do |role|
      git_plugin.rpush_switch_user(role) do
        if test "[ -f #{fetch(:rpush_conf)} ]"
          info "using conf file #{fetch(:rpush_conf)}"
        else
          invoke 'rpush:check'
        end
        git_plugin.each_process_with_index do |pid_file, index|
          unless git_plugin.pid_file_exists?(pid_file) && git_plugin.process_exists?(pid_file)
            git_plugin.start_rpush(pid_file, index)
          end
        end
      end
    end
  end

  desc 'Status rpush'
  task :status do
    on roles (fetch(:rpush_role)) do |role|
      git_plugin.rpush_switch_user(role) do
        if test "[ -f #{fetch(:rpush_conf)} ]"
          git_plugin.status_rpush
        end
      end
    end
  end

  desc 'Stop rpush'
  task :stop do
    on roles (fetch(:rpush_role)) do |role|
      git_plugin.rpush_switch_user(role) do
        git_plugin.each_process_with_index(reverse: true) do |pid_file, index|
          if git_plugin.pid_file_exists?(pid_file) && git_plugin.process_exists?(pid_file)
            git_plugin.stop_rpush(pid_file)
          end
        end
      end
    end
  end
end

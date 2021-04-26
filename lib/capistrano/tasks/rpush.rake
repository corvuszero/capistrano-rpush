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
        pid_file_list = Array.new(fetch(:rpush_processes)) do |index|
          fetch(:rpush_pid).gsub(/\.pid$/, "-#{index}.pid")
        end
        pid_file_list.reverse!

        pid_file_list.each_with_index do |pid_file, index|
          if test("[ -f #{pid_file} ]") && test("kill -0 $( cat #{pid_file} )")
            within current_path do
              with rack_env: fetch(:rpush_env) do
                execute :timeout, "-s SIGKILL #{fetch(:rpush_stop_timeout)}", :rpush, "stop -p #{pid_file.to_s} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
              end
            end
          end

          within current_path do
            with rack_env: fetch(:rpush_env) do
              execute :rpush, "start -p #{pid_file.to_s} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
            end
          end
        end
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

        pid_file_list = Array.new(fetch(:rpush_processes)) do |index|
          fetch(:rpush_pid).gsub(/\.pid$/, "-#{index}.pid")
        end

        pid_file_list.each_with_index do |pid_file, index|
          unless test("[ -f #{pid_file} ]") && test("kill -0 $( cat #{pid_file} )")
            within current_path do
              with rack_env: fetch(:rpush_env) do
                execute :rpush, "start -p #{pid_file.to_s} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
              end
            end
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
          within current_path do
            with rack_env: fetch(:rpush_env) do
              execute :rpush, "status -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
            end
          end
        end
      end
    end
  end

  desc 'Stop rpush'
  task :stop do
    on roles (fetch(:rpush_role)) do |role|
      git_plugin.rpush_switch_user(role) do
        pid_file_list = Array.new(fetch(:rpush_processes)) do |index|
          fetch(:rpush_pid).gsub(/\.pid$/, "-#{index}.pid")
        end
        pid_file_list.reverse!

        pid_file_list.each_with_index do |pid_file, index|
          unless test("[ -f #{pid_file} ]") && test("kill -0 $( cat #{pid_file} )")
            within current_path do
              with rack_env: fetch(:rpush_env) do
                execute :timeout, "-s SIGKILL #{fetch(:rpush_stop_timeout)}", :rpush, "stop -p #{pid_file.to_s} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
              end
            end
          end
        end
      end
    end
  end
end

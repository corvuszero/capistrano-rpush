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
          unless pid_file_exists?(pid_file) && process_exists?(pid_file)
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

  def each_process_with_index reverse: false
    pid_file_list = git_plugin.pid_files
    pid_file_list.reverse! if reverse
    pid_file_list.each_with_index do |pid_file, index|
      yield(pid_file, index)
    end
  end

  def pid_files
    Array.new(fetch(:rpush_processes)) do |index|
          fetch(:rpush_pid).gsub(/\.pid$/, "-#{index}.pid")
    end
  end

  def pid_file_exists? pid_file
    test "[ -f #{pid_file} ]"
  end

  def process_exists? pid_file
    test "kill -0 $( cat #{pid_file} )"
  end

  def stop_rpush pid_file
    within current_path do
      with rack_env: fetch(:rpush_env) do
        execute :rpush, "stop -p #{pid_file.to_s} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
      end
    end
  end

  def start_rpush pid_file
    within current_path do
      with rack_env: fetch(:rpush_env) do
        execute :rpush, "start -p #{pid_file.to_s} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
      end
    end
  end

  def status_rpush
    within current_path do
      with rack_env: fetch(:rpush_env) do
        execute :rpush, "status -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
      end
    end
  end
end

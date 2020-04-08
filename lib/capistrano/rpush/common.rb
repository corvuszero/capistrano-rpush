module Capistrano
  module RpushPlugin
    module Common

      def rpush_switch_user role, &block
        user = rpush_user role
        if user == role.user
          block.call
        else
          as user do
            block.call
          end
        end
      end

      def rpush_user role
        properties = role.properties
        properties.fetch(:rpush_user) ||  # local property for rpush only
        fetch(:rpush_user) ||
        properties.fetch(:run_as) ||      # global property across multiple capistrano gems
        role.user
      end

      def each_process_with_index reverse: false
        pid_file_list = pid_files
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
  end
end

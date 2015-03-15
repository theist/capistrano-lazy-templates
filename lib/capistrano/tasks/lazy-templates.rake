require 'capistrano/lazy-templates/helpers'

include Capistrano::LazyTemplates::Helpers

namespace :load do
  task :defaults do
    set :template_dir, 'config/templates'
    set :role_templates, %w(all)
  end
end


namespace :lazy_templates do
  desc "get a FILE file or directory recursively from server"
  task :get do
    role = ENV['ROLE'] || "all"
    file = ENV['FILE']
    local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
    on roles(role.to_sym) do
      get_remote_file(file,local_base)
    end
  end

  desc "Get files or directories listed in a FILE filelist"
  task :get_file_list do
    role = ENV['ROLE'] || "all"
    filelist = ENV['FILE']
    local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
    on roles(role.to_sym) do
      if File::exists?(filelist)
        File::new(filelist).readlines.each do |file|
          get_remote_file(file,local_base)
        end
      else
        error "cannot open #{filelist} for open"
      end
    end
  end

  desc "Upload files or templates to specified ROLES"
  task :upload_files do
    roles_array = fetch(:role_templates)
    roles_array = [ENV['ROLE']] if ENV['ROLE'];
    roles_array.each do |role|
      on roles(role.to_sym) do
        local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
        Dir["#{local_base}/**/*"].each do |file|
          if File.file?(file)
            if File.extname(file) == '.erb'
              erb = File.read(file)
              random_foo = (1000000000 * rand).round.to_s
              res = ERB.new(erb).result(binding)
              upload! StringIO.new(res), "/tmp/template#{random_foo}"
              sudo "cp /tmp/template#{random_foo} " + file.gsub(/^#{local_base}/,'').gsub(/\.erb$/,'')
              execute "rm /tmp/template#{random_foo}"
            else
              random_foo = (1000000000 * rand).round.to_s
              upload! file, "/tmp/template#{random_foo}"
              sudo "cp /tmp/template#{random_foo} " + file.gsub(/^#{local_base}/,'')
              execute "rm /tmp/template#{random_foo}"
            end
          end
        end
      end
    end
  end

  desc "Updates only existing files"
  task :update_files do
    roles_array = fetch(:role_templates)
    roles_array = [ENV['ROLE']] if ENV['ROLE']
    roles_array.each do |role|
      on roles(role.to_sym) do
        local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
        Dir["#{local_base}/**/*"].each do |file|
          if File.file?(file)
            get_remote_file(file.gsub(/^#{local_base}/,''),local_base)
          end
        end
      end
    end
  end

end

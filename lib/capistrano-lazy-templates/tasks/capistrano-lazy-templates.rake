def get_remote_file(file,local_base)  ## Or dir!
  if File::directory?(local_base)
    file = file.chomp
    if test("[ -d #{file} ]")
      if test("[ -r #{file} ]")
        file = file + "/" unless file =~ /\/$/
        contents = capture :ls, file
        contents.each_line do |sub_file|
          get_remote_file(file + sub_file ,local_base)
        end
      end
    else
      if test("[ -r  #{file} ]")
        if test("[ -f #{file} ]")
          FileUtils::mkdir_p(File::dirname(local_base + file))
          download! file ,local_base + file 
        else
          warn "Cannot read regular file: #{file}"
        end
      end
    end
  else
    error "#{local_base} must exists before pick remote server files"
  end
end

set :template_dir, 'config/templates'
set :role_templates, %w(all)

namespace :lazy_templates do
  task :get do
    role = ENV['ROLE'] || "all"
    file = ENV['FILE']
    local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
    on roles(role) do
      get_remote_file(file,local_base)
    end
  end

  task :get_file_list do
    role = ENV['ROLE'] || "all"
    filelist = ENV['FILE']
    local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
    on roles(role) do
      if File::exists?(filelist)
        File::new(filelist).readlines.each do |file|
          get_remote_file(file,local_base)
        end
      else
        error "cannot open #{filelist} for open"
      end
    end
  end

  task :upload_files do
    roles_array = fetch(:role_templates)
    roles_array = [ENV['ROLE']] if ENV['ROLE'];
    roles_array.each do |role|
      on roles(role) do
        local_base = fetch(:template_dir) + "/" + fetch(:stage).to_s + '/' + role
        info "role #{role} #{local_base}"
        Dir["#{local_base}/**/*"].each do |file|
          if File.file?(file)
            if File.extname(file) == '.erb'
              binding.pry
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
end

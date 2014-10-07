module Capistrano
  module LazyTemplates
    module Helpers

      def get_remote_file(file,local_base)  ## Or dir!
        if File::directory?(local_base)
          file = file.chomp
          if test("[ -d #{file} ]")
            if test("[ -r #{file} ]")
              file = file + "/" unless file =~ /\/$/
              contents = capture :ls, "-1 #{file}"
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

    end
  end
end

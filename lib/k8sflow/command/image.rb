require 'erb'
module K8sflow

  module Image
    class ImageBase < Clitopic::Command::Base
      class << self

        def kv_parse(list)
          vars = {}
          list.each do |e|
            sp = e.split("=")
            key = sp[0..-2].join("=")
            value = sp[-1]
            vars[key] = value
          end
          return vars
        end

        def vars
          if @vars.nil?
            @vars = {}
            if !options[:build_vars].nil?
              if options[:build_vars].is_a?(Hash)
                @vars = options[:build_vars]
              else
                @vars = kv_parse(options[:build_vars])
              end
            end
            if !options[:vars].nil?
              if options[:vars].is_a?(Hash)
                @vars.merge!(options[:vars])
              else
                @vars.merge!(kv_parse(options[:vars]))
              end
            end
          end

          @vars["tag"] = @options[:tag]
          return @vars
        end

        def files
          f = []
          options[:files].each do |file|
            if !file.start_with?("/")
              file = "#{@options[:path]}/#{file}"
            end
            file_list = Dir.glob(file)
            f << file_list
          end
          return f
        end

        def tag
          @options[:tag]
        end


        def create_dockerfile
          tag = @options[:tag]
          dir = "#{@options[:path]}/#{@options[:tag]}"
          puts "- Remove previous dir: #{dir}"
          FileUtils.rm_rf dir
          puts "- Create dir: #{dir}"
          FileUtils.mkdir_p dir
          files.each do |file_list|
            puts "- Copy files: #{file_list}"
            FileUtils.cp(file_list, dir)
          end
          puts "- Read Dockerfile template: #{@options[:path]}/#{@options[:tpl]}"
          tpl = "#{@options[:path]}/#{@options[:tpl]}"
          File.open(tpl, 'rb') do |file|
            tpl = file.read
          end
          b = binding
          puts "- Write Dockerfile: #{dir}/Dockerfile"
          puts "  with vars:\n#{vars.map{|k,v| "   #{k}: #{v}"}.join("\n")}"
          File.open("#{dir}/Dockerfile", 'wb') do |file|
            file.write(ERB.new(tpl).result b)
          end

          puts  "-----------------------------------------------"
        end

        def dockerbuild
          dir = "#{@options[:path]}/#{@options[:tag]}"
          cmd = "docker -H #{@options[:docker_api]} build #{@options[:build_opts]} -t #{@options[:registry]}:#{tag}  #{dir} "
          puts cmd
          system(cmd)
        end

        def dockerpush
          cmd = "docker -H #{@options[:docker_api]}  push #{@options[:registry]}:#{tag}"
          puts cmd
          system(cmd)
        end

      end
    end


    class ImageTopic < Clitopic::Topic::Base
      register name: 'image',
      description: 'Mange image lifecylces'

      option :registry, '-r', '--registry DOCKER_REPO', 'Docker registry to pull/fetch images'
      option :path, '-p',  '--path DOCKERFILE PATH', 'dockerfiles source directory to'
      option :build_vars, "--build-vars key=value,key=value" , Array, "Default variables"
      option :docker_api, "-H", "--host", "docker api endpoint", default: "tcp://localhost:4243"
      option :tag, '-t', '--tag TAG', "Image tag", default: 'latest'
    end


    class Dockerfile < ImageBase
      register name: 'dockerfile',
      banner: 'image:dockerfile [options]',
      description: 'Generate a dockerfile with templated vars .',
      topic: 'image'

      option :files, "-f", "--files FILE1,FILE2", Array, "List files to copy in dockerfile directory, i.e 'files/*',/etc/conf.cfg'"
      option :tpl, "-l", "--tpl=Dockerfile", "The Dockerfile Template", default: 'Dockerfile.tpl'
      option :vars, "-x", "--vars=VARS", Array, "Variables required by the dockerfile"
      option :tag, '-t', '--tag TAG', "Image tag", default: 'master'

      def self.call
        create_dockerfile
      end
    end

    class Build < ImageBase
      register name: 'build',
      description: 'build docker image',
      banner: 'image:build [OPTIONS]',
      topic: 'image'

      option :build, "--build OPTS", "docker build options"
      def self.call
        dockerbuild
      end
    end

    class Push < ImageBase
      register name: 'push',
      description: 'push dockerimage to docker hub',
      banner: 'image:push [OPTIONS]',
      topic: 'image'

      option :build, "--build=[OPTS]", "docker build options"
      def self.call
        dockerbuild if @options[:build] != nil
        dockerpush
      end
    end

    class List < Clitopic::Command::Base
      register name: 'list',
      description: 'List available tags in a registry',
      topic: 'image'

      def self.call
      end
    end
  end

end

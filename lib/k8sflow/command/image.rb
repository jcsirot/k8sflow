require 'erb'
module K8sflow

  module Image
    class ImageBase
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
            puts @vars
          end
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

        def branch
          @options[:branch]
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
          puts "- Read Dockerfile template"
          tpl = "#{@options[:path]}/#{@options[:tpl]}"
          File.open(tpl, 'rb') do |file|
            tpl = file.read
          end
          b = binding
          puts "- Write Dockerfile"
          File.open("#{dir}/Dockerfile", 'wb') do |file|
            file.write(ERB.new(tpl).result b)
          end

          puts  "-----------------------------------------------"
        end

        def exec_docker_build(tag)
          @build = @builds[tag]
          puts @build
          puts tag
          @build[:docker] ||= {}
          @build[:docker][:build] = "docker -H #{@docker_api} build -t #{vars['registry']}:#{tag} -f #{tag}/Dockerfile ."
          puts "docker build -t #{vars['registry']}:#{tag} -f #{tag}/Dockerfile"
          system(@build[:docker][:build])
        end

        def exec_docker_push(tag)
          @build = @builds[tag]
          @build[:docker] ||= {}
          @build[:docker][:push] = "docker -H #{@docker_api} push #{vars['registry']}:#{tag}"
          puts "docker push #{vars['registry']}:#{tag}"
          system(@build[:docker][:push])
        end

        def dockerbuilds(tag=nil)
          if tag.nil?
            threads = []
            @builds.each do |t, b|
              threads << Thread.new {exec_docker_build(t)}
            end
            threads.each { |thr| thr.join }
          else
            exec_docker_build(tag)
          end
        end

        def dockerpush(tag=nil)
          if tag.nil?
            threads = []
            @builds.each do |t, b|
              threads << Thread.new {exec_docker_push(t)}
            end
            threads.each { |thr| thr.join }
          else
            exec_docker_push(tag)
          end
        end

      end
    end


    class ImageTopic < Clitopic::Topic::Base
      register name: 'image',
      description: 'Mange image lifecylces'

      option :repository, '-r', '--repository DOCKER_REPO', 'Docker repository to pull/fetch images'
      option :path, '-p',  '--path DOCKERFILE PATH', 'dockerfiles source directory to'
      option :build_vars, "--build-vars key=value,key=value" , Array, "Default variables"
      option :docker_api, "-h", "--host", "docker api endpoint", default: "tcp://localhost:4243"
    end


    class Dockerfile < Clitopic::Command::Base
      register name: 'dockerfile',
      banner: 'dockerfile [options]',
      description: 'Generate a dockerfile with templated vars .',
      topic: 'image'

      option :files, "-f", "--files FILE1,FILE2", Array, "List files to copy in dockerfile directory, i.e 'files/*',/etc/conf.cfg'"
      option :tpl, "-l", "--tpl=Dockerfile", "The Dockerfile Template", default: 'Dockerfile.tpl'
      option :vars, "-x", "--vars=VARS", "Variables required by the dockerfile"
      option :tag, '-t', '--tag TAG', "Image tag", default: 'latest'
      option :tag, '-b', '--branch BRANCH', "Image tag", default: 'master'

      def self.call
        #      puts @options
        create_dockerfile
      end
    end

    class Push < Clitopic::Command::Base
      register name: 'push',
      description: 'push image to docker  registry',
      banner: 'push [options] tag',
      topic: 'image'

      def self.call
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

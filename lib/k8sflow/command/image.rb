module K8sflow
  module Image
    class ImageTopic < Clitopic::Topic::Base
      register name: 'image',
      description: 'Mange image lifecylces'

      option :repository, '-r', '--repository DOCKER_REPO', 'Docker repository to pull/fetch images'
      option :git, '--git GIT_REPO', 'dockerfiles source repo/directory to pull/push them automaticaly'
    end

    class Dockerfile < Clitopic::Command::Base
      register name: 'dockerfile',
      banner: 'dockerfile [options]',
      description: 'Generate a dockerfile with templated vars .',
      topic: 'image'

      option :src, '-s', '--source', "Dockerfile template"
      option :dest, '-o', '--output dockerfile', "Output dockerfile. can be templated by the vars using {{VAR}}"
      option :vars, "-x", "--vars key=value,key2=value2", "Variables required by the dockerfile template"

      option :tag, '-t', '--tag TAG', "Image tag", default: 'latest'
      option :build, "-b", "--build", "Trigger docker build"
      def self.call
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

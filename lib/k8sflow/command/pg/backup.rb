require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg


    class Backup < PgBase
      register name: 'backup',
               description: 'Create a database backup and send it to a [remote] directory',
               topic: 'pg'

      option :src, "--src=file", "Dump to store"
      option :aws_access_id, "--aws-access-id", "Aws S3 access id"
      option :aws_secret, "--aws-secret", "Aws S3 secret"
      option :bucket, "--bucket", "Aws bucket"
      option :dest, "--dest", "File name"

      def self.call
        echo "store to aws"
        echo "Upload the file #{@options[:src]} to #{options[:bucket]}/#{options[:dest]}"
      end
    end

  end
end

require 'uri'
require_relative 'pg_base'

module K8sflow
  module Pg

    class Dump < PgBase
      register name: 'dump',
               description: 'Create a database dump and store in a localfile',
               topic: 'pg'

      option :dest, "--dest=DIR", "dest directory", default: "/tmp"
      option :ssl, "--ssl"

      def self.call
        file = File.new("#{options[:dest]}/#{database[:database]}_#{database[:host]}_#{Time.now.iso8601}.dump", 'wb')

        puts ("PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} pg_dump -p #{database[:port]} --host #{database[:host]} --username #{database[:user]} --clean --format=c --no-owner --no-acl -d #{database[:database]} > #{file.path}")
        exec("PGSSLMODE=#{ssl?} PGPASSWORD=#{database[:password]} pg_dump -p #{database[:port]} --host #{database[:host]} --username #{database[:user]} --clean --format=c --no-owner --no-acl -d #{database[:database]} > #{file.path}")

        file.close
      end
    end

  end
end

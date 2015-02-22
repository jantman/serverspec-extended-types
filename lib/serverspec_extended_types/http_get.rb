##############################################################################
# serverspec-extended-types - http_get
#
# <https://github.com/jantman/serverspec-extended-types>
#
# Copyright (C) 2015 Jason Antman <jason@jasonantman.com>
#
# Licensed under the MIT License - see LICENSE.txt
#
##############################################################################

require 'timeout'
require 'faraday'

module Serverspec
  module Type

    class Http_Get < Base

      def initialize(port, host_header, path)
        @ip = ENV['SERVERSPEC_TARGET_HOST']
        @port = port
        @host = host_header
        @path = path
        @timed_out_status = false
        @content_str = nil
        @headers_hash = nil
        @response_code_int = nil
        begin
          Timeout::timeout(10) do
            getpage
          end
        rescue Timeout::Error
          @timed_out_status = true
        end
      end

      def getpage
        ip = @ip
        port = @port
        conn = Faraday.new("http://#{ip}:#{port}/")
        conn.headers[:user_agent] = 'Serverspec::Type::Http_Get (jantman/ec2machines)'
        conn.headers[:Host] = @host
        response = conn.get(@path)
        @response_code_int = response.status
        @content_str = response.body
        @headers_hash = Hash.new('')
        response.headers.each do |header, val|
          #define_method("header_#{header}") do
          #  @headers_hash[val]
          #end
          @headers_hash[header] = val
        end
      end

      def timed_out?
        @timed_out_status
      end

      def headers
        @headers_hash
      end

      def status
        if @timed_out_status
          0
        else
          @response_code_int
        end
      end

      def body
        @content_str
      end
    end

    def http_get(port, host_header, path)
      Http_Get.new(port, host_header, path)
    end
  end
end

include Serverspec::Type

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
require 'serverspec_extended_types/version'

module Serverspec
  module Type

    # Perform an HTTP GET request against the serverspec target
    # using {http://www.rubydoc.info/gems/faraday/ Faraday}.
    class Http_Get < Base

      # Initialize a bunch of instance variables, then call {#getpage}
      #
      # Calls {#getpage} within a {Timeout::timeout} block;
      # If {#getpage} times out, set ``timed_out_status`` to [True]
      #
      # @param port [Int] the port to connect to HTTP over
      # @param host_header [String] the value to set in the 'Host' HTTP request header
      # @param path [String] the URI/path to request from the server
      # @param timeout_sec [Int] how many seconds to allow request to run before timing out and setting @timed_out_status to True
      #
      # @example
      #   describe http_get(80, 'myhostname', '/') do
      #     # tests here
      #   end
      #
      # @api public
      # @return [nil]
      def initialize(port, host_header, path, timeout_sec=10)
        @ip = ENV['SERVERSPEC_TARGET_HOST']
        @port = port
        @host = host_header
        @path = path
        @timed_out_status = false
        @content_str = nil
        @headers_hash = nil
        @response_code_int = nil
        begin
          Timeout::timeout(timeout_sec) do
            getpage
          end
        rescue Timeout::Error
          @timed_out_status = true
        end
      end

      # Private method to actually get the page; must be called within a timeout block
      #
      # Gets the page using {http://www.rubydoc.info/gems/faraday/ Faraday} and then sets instance variables for the various attribute readers.
      #
      # @api private
      # @return [nil]
      def getpage
        ip = @ip
        port = @port
        conn = Faraday.new("http://#{ip}:#{port}/")
        version = ServerspecExtendedTypes::VERSION
        conn.headers[:user_agent] = "Serverspec::Type::Http_Get/#{version} (https://github.com/jantman/serverspec-extended-types)"
        conn.headers[:Host] = @host
        response = conn.get(@path)
        @response_code_int = response.status
        @content_str = response.body
        @headers_hash = Hash.new('')
        response.headers.each do |header, val|
          @headers_hash[header] = val
        end
      end

      # Whether or not the request timed out
      #
      # @example
      #   describe http_get(80, 'myhostname', '/') do
      #     it { should_not be_timed_out }
      #   end
      #
      # @api public
      # @return [Boolean]
      def timed_out?
        @timed_out_status
      end

      # Returns the HTTP response headers as a hash
      #
      # @example
      #   describe http_get(80, 'myhostname', '/') do
      #     its(:headers) { should include('HeaderName' => /value regex/ }
      #   end
      #
      # @api public
      # @return [Hash]
      def headers
        @headers_hash
      end

      # Returns the HTTP status code, or 0 if timed out
      #
      # @example
      #   describe http_get(80, 'myhostname', '/') do
      #     its(:status) { should eq 200 }
      #   end
      #
      # @api public
      # @return [Int]
      def status
        if @timed_out_status
          0
        else
          @response_code_int
        end
      end

      # Returns the body/content of the HTTP response
      #
      # @example
      #   describe http_get(80, 'myhostname', '/') do
      #     its(:body) { should match /<html>/ }
      #   end
      #
      # @api public
      # @return [String]
      def body
        @content_str
      end

      private :getpage
    end

    # ServerSpec Type wrapper for http_get
    #
    # @example
    #   describe http_get(80, 'myhostname', '/') do
    #     # tests here
    #   end
    #
    # @param port [Int] the port to connect to HTTP over
    # @param host_header [String] the value to set in the 'Host' HTTP request header
    # @param path [String] the URI/path to request from the server
    # @param timeout_sec [Int] how many seconds to allow request to run before timing out and setting @timed_out_status to True
    #
    # @api public
    # @return [Serverspec::Type::Http_Get]
    def http_get(port, host_header, path, timeout_sec=10)
      Http_Get.new(port, host_header, path, timeout_sec=timeout_sec)
    end
  end
end

include Serverspec::Type

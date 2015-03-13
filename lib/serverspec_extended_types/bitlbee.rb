##############################################################################
# serverspec-extended-types - bitlbee
#
# <https://github.com/jantman/serverspec-extended-types>
#
# Copyright (C) 2015 Jason Antman <jason@jasonantman.com>
#
# Licensed under the MIT License - see LICENSE.txt
#
##############################################################################
#
# Many thanks to the blog posts that helped me with this:
# <http://ghost.ponpokopon.me/add-custom-matcher-of-serverspec/>
# <http://arlimus.github.io/articles/custom.resource.types.in.serverspec/>
#
##############################################################################
require 'socket'
require 'openssl'
require 'timeout'
require 'serverspec'
require 'serverspec/type/base'

module Serverspec
  module Type

    class Bitlbee < Base

      # Bitlbee constructor
      #
      # Connects to Bitlbee on the host specified by ENV['TARGET_HOST']
      #
      # @api public
      #
      # @example Constructor
      #   describe bitlbee(6697, 'nick', 'password') do
      #     it { should be_virtualenv }
      #   end
      #
      # @param port [Integer] the port to connect to
      # @param nick [String] the nick to connect as
      # @param password [String] the password for nick
      # @param use_ssl [Boolean] whether to connect with SSL
      def initialize(port, nick, password, use_ssl=false)
        @port = port
        @host = ENV['TARGET_HOST']
        @nick = nick
        @use_ssl = use_ssl
        @password = password
        @connected_status = false
        @version_str = ""
        @timed_out_status = false
        @started = false
      end

      # Begin timeout-wrapped connection
      #
      # This just calls {#connect} within a 10-second {Timeout::timeout} wrapper,
      # and handles both timeout and {Errno::ECONNREFUSED}.
      #
      # @api private
      # @return [nil]
      def start
        @started = true
        begin
          Timeout::timeout(10) do
            @use_ssl ? ( connect_ssl ) : ( connect )
          end
        rescue Timeout::Error
          @timed_out_status = true
        rescue Errno::ECONNREFUSED
          @connected_status = false
        end
      end

      # connection to the IRC server (without SSL)
      #
      # @api private
      # @return [nil]
      def connect
        @socket = TCPSocket.open(@host, @port)
        communicate
        @socket.puts("QUIT :\"outta here\"\n")
        @socket.close
      end

      # Open SSL connection to the IRC server
      #
      # @api private
      # @return [nil]
      def connect_ssl
        sock = TCPSocket.open(@host, @port)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
        @socket = OpenSSL::SSL::SSLSocket.new(sock, ctx).tap do |socket|
          socket.sync_close = true
          socket.connect
        end
        communicate
        @socket.puts("QUIT :\"outta here\"\n")
        @socket.close
      end

      # Login to IRC and get version, over @socket
      #
      # @api private
      # @return [nil]
      def communicate
        password = @password
        nick = @nick
        @socket.puts("PASS #{password}\n")
        @socket.puts("NICK #{nick}\n")
        @socket.puts("USER #{nick} #{nick} servername :TestUser\n")
        while buf = (@socket.readpartial(1024) rescue nil )
          @connected_status = true
          (data||="") << buf
          if data =~ /Welcome to the/
            @socket.puts("MODE #{nick} +i\n")
            data = ""
          elsif data =~ /If you've never/
            @socket.puts("PRIVMSG &bitlbee :identify #{password}\n")
            data = ""
          elsif data =~ /PING (\S+)/
            @socket.puts(":#{$1} PONG #{$1} :#{$1}\n")
            data = ""
          elsif data =~ /MODE #{nick} :\+i/
            break
          end
        end
        @socket.puts("PRIVMSG root :\001VERSION\001\n")
        while buf = (@socket.readpartial(1024) rescue nil )
          (data||="") << buf
          if data =~ /VERSION (.+)/
            @version_str = $1
            break
          end
        end
      end

      # Check whether the connection timed out
      #
      # @example serverspec test
      #   describe bitlbee(6697, 'myuser', 'mypass') do
      #     it { should_not be_timed_out }
      #   end
      #
      # @api public
      # @return [Boolean]
      def timed_out?
        start if not @started
        @timed_out_status
      end

      # Check whether we can successfully connect
      #
      # @example serverspec test
      #   describe bitlbee(6697, 'myuser', 'mypass') do
      #     it { should be_connectable }
      #   end
      #
      # @api public
      # @return [Boolean]
      def connectable?
        start if not @started
        @connected_status
      end

      # Return the version string from Bitlbee
      #
      # @example
      #   describe bitlbee(6697, 'myuser', 'mypass') do
      #     its(:version) { should match /foo/ }
      #   end
      #
      # @api public
      # @return [String]
      def version
        start if not @started
        @version_str
      end
      
    end

    # Serverspec Type method for Bitlbee
    #
    # @example
    #   describe bitlbee(6697, 'myuser', 'mypass') do
    #     # tests here
    #   end
    #
    # @api public
    #
    # @param port [Integer] the port to connect to
    # @param nick [String] the nick to connect as
    # @param password [String] the password for nick
    # @param use_ssl [Boolean] whether to connect with SSL
    #
    # @return {Serverspec::Type::Bitlbee} instance
    def bitlbee(port, nick, password, use_ssl=false)
      Bitlbee.new(port, nick, password, use_ssl)
    end
  end
end

include Serverspec::Type

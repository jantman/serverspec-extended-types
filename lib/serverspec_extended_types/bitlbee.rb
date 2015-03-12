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

      def initialize(port, nick, password)
        @port = port
        @host = ENV['TARGET_HOST']
        @nick = nick
        @password = password
        @connected_status = false
        @version_str = ""
        @timed_out_status = false
        begin
          Timeout::timeout(10) do
            connect
          end
        rescue Timeout::Error
          @timed_out_status = true
        rescue Errno::ECONNREFUSED
          @connected_status = false
        end
      end

      def connect
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

      def communicate
        password = @password
        nick = @nick
        @socket.puts("PASS #{password}\n")
        @socket.puts("NICK #{nick}\n")
        @socket.puts("USER #{nick} #{nick} ec2a-live.jasonantman.com :Jason Antman\n")
        while buf = (@socket.readpartial(1024) rescue nil )
          @connected_status = true
          (data||="") << buf
          if data =~ /Welcome to the/
            @socket.puts("MODE #{nick} +i\n")
            data = ""
          elsif data =~ /If you've never/
            @socket.puts("PRIVMSG &bitlbee :identify #{password}\n")
            data = ""
          elsif data =~ /PING/
            @socket.puts(":ec2a-live.jasonantman.com PONG ec2a-live.jasonantman.com :ec2a-live.jasonantman.com")
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
      
      def timed_out?
        @timed_out_status
      end
      
      def connectable?
        @connected_status
      end

      def version
        @version_str
      end
      
    end

    def bitlbee(port, nick, password)
      Bitlbee.new(port, nick, password)
    end
  end
end

include Serverspec::Type

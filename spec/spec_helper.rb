$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
end

require 'codecov'
if ENV['CI']=='true'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'specinfra'
require 'rspec/mocks/standalone'
require 'rspec/its'
require 'specinfra/helper/set'
include Specinfra::Helper::Set

set :backend, :exec

set :os, :family => 'linux'

module Specinfra
  module Backend
    class Ssh
      def run_command(cmd, opts={})
        CommandResult.new :stdout => nil, :exit_status => 0
      end
    end
  end
end

module GetCommand
  def get_command(method, *args)
    Specinfra.command.get(method, *args)
  end
end

include GetCommand


require 'serverspec_extended_types'

##############################################################################
# serverspec-extended-types - virtualenv
#
# <https://github.com/jantman/serverspec-extended-types>
#
# Copyright (C) 2015 Jason Antman <jason@jasonantman.com>
#
# Licensed under the MIT License - see LICENSE.txt
#
##############################################################################

module Serverspec::Type
  class Virtualenv < Base

    def virtualenv?
      pip_path = ::File.join(@name, 'bin', 'pip')
      python_path = ::File.join(@name, 'bin', 'python')
      libpath = ::File.join(@name, 'lib', 'python2.7', 'site-packages')
      backend.check_executable(pip_path, 'root') and @runner.check_file_is_executable(python_path, 'root') and @runner.check_file_is_directory(libpath)
    end

    private
    def pip_freeze()
      if not @pip_freeze.nil?
        return @pip_freeze
      end
      tmp = @runner.run_command("#{pip_path} freeze")
      @pip_freeze = Hash.new()
      if tmp.exit_status.to_i != 0
        return @pip_freeze
      end
      lines = tmp.split()
      lines.each do |line|
        line.strip!
        parts = line.split(/==/)
        @pip_freeze[parts[0]] = parts[1]
      end
      @pip_freeze
    end

    private
    def pip_version()
      pip_path = ::File.join(@name, 'bin', 'pip')
      @pip_version ||= @runner.run_command("#{pip_path} --version")
    end

    private
    def python_version()
      python_path = ::File.join(@name, 'bin', 'python')
      @python_version ||= @runner.run_command("#{python_path} --version")
    end
  end

  def virtualenv(name)
    Virtualenv.new(name)
  end
end

include Serverspec::Type

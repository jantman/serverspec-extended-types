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
      act_path = ::File.join(@name, 'bin', 'activate')
      cmd = "grep -q 'export VIRTUAL_ENV' #{act_path}"
      @runner.check_file_is_executable(pip_path, 'root') and
        @runner.check_file_is_executable(python_path, 'root') and
        @runner.check_file_is_executable(act_path, 'root') and
        @runner.run_command(cmd).exit_status.to_i == 0
    end

    def pip_version
      @pip_version || get_pip_version
    end

    def python_version
      @python_version || get_python_version
    end

    def pip_freeze
      @pip_freeze || get_pip_freeze
    end
    
    private
    def get_pip_freeze()
      pip_path = ::File.join(@name, 'bin', 'pip')
      tmp = @runner.run_command("#{pip_path} freeze")
      @pip_freeze = Hash.new()
      if tmp.exit_status.to_i != 0
        return @pip_freeze
      end
      lines = tmp.stdout.split("\n")
      lines.each do |line|
        line.strip!
        if line =~ /^-e /
          @pip_freeze[line] = ''
          next
        end
        parts = line.split(/==/)
        @pip_freeze[parts[0]] = parts[1]
      end
      @pip_freeze
    end

    private
    def get_pip_version()
      pip_path = ::File.join(@name, 'bin', 'pip')
      pip_path = ::File.join(@name, 'bin', 'pip')
      tmp = @runner.run_command("#{pip_path} --version")
      if ( tmp.stdout =~ /^pip (\d+\S+)/ )
        @pip_version = $1
      else
        @pip_version = ''
      end
    end

    private
    def get_python_version()
      python_path = ::File.join(@name, 'bin', 'python')
      tmp = @runner.run_command("#{python_path} --version")
      if ( tmp.stderr =~ /^[Pp]ython (\d+\S+)/ )
        @python_version = $1
      elsif ( tmp.stdout =~ /^[Pp]ython (\d+\S+)/ )
        @python_version = $1
      else
        @python_version = ''
      end
    end
  end

  def virtualenv(name)
    Virtualenv.new(name)
  end
end

include Serverspec::Type

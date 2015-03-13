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

    # Test whether this appears to be a working venv
    #
    # Tests performed:
    # - venv_path/bin/pip executable by root?
    # - venv_path/bin/python executable by root?
    # - venv_path/bin/activate executable by root?
    # - 'export VIRTUAL_ENV' in venv_path/bin/activate?
    #
    # @example
    #   describe virtualenv('/path/to/venv') do
    #     it { should be_virtualenv }
    #   end
    #
    # @api public
    # @return [Boolean]
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

    # Return the version of pip installed in the virtualenv
    #
    # @example
    #   describe virtualenv('/path/to/venv') do
    #     its(:pip_version) { should match /^6\.0\.6$/ }
    #   end
    #
    # @api public
    # @return [String]
    def pip_version
      @pip_version || get_pip_version
    end

    # Return the version of python installed in the virtualenv
    #
    # @example
    #   describe virtualenv('/path/to/venv') do
    #     its(:python_version) { should match /^2\.7\.9$/ }
    #   end
    #
    # @api public
    # @return [String]
    def python_version
      @python_version || get_python_version
    end

    # Return a hash of all packages present in `pip freeze` output for the venv
    #
    # Note that any editable packages (`-e something`) are returned as hash keys
    # with an empty value
    #
    # @example
    #   describe virtualenv('/path/to/venv') do
    #     its(:pip_freeze) { should include('wsgiref' => '0.1.2') }
    #     its(:pip_freeze) { should include('requests') }
    #     its(:pip_freeze) { should include('pytest' => /^2\.6/) }
    #     its(:pip_freeze) { should include('-e git+git@github.com:jantman/someproject.git@1d8a380e3af9d081081d7ef685979200a7db4130#egg=someproject') }
    #   end
    #
    # @api public
    # @return [Hash]
    def pip_freeze
      @pip_freeze || get_pip_freeze
    end
    
    private
    # Get a hash for the `pip freeze` output; set @pip_freeze
    #
    # @api private
    # @return [nil]
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
    # Get the pip version from the venv; set @pip_version
    #
    # @api private
    # @return [nil]
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
    # Get the python version from the venv; set @python_version
    #
    # @api private
    # @return [nil]
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

  # Serverspec Type wrapper method for Serverspec::Type::Virtualenv
  #
  # @example
  #   describe virtualenv('/path/to/venv') do
  #     # tests here
  #   end
  #
  # @param name [String] the absolute path to the virtualenv root
  #
  # @api public
  # @return {Serverspec::Type::Virtualenv}
  def virtualenv(name)
    Virtualenv.new(name)
  end
end

include Serverspec::Type

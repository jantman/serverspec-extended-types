require 'spec_helper'
require 'serverspec_extended_types/virtualenv'
require 'specinfra'

describe 'Serverspec::Type#virtualenv' do
  context 'constructor' do
    it 'instantiates the class with the correct parameters' do
      expect(Serverspec::Type::Virtualenv).to receive(:new).with('/foo/bar')
      virtualenv('/foo/bar')
    end
    it 'returns the new object' do
      expect(Serverspec::Type::Virtualenv).to receive(:new).and_return("foo")
      expect(virtualenv('/foo/bar')).to eq "foo"
    end
  end
  context '#virtualenv?' do
    it 'checks all files' do
      v = virtualenv('/foo/bar')
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/pip', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/python', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_readable).once.ordered.with('/foo/bar/bin/activate', 'owner').and_return(true)
      res = Specinfra::CommandResult.new({:stdout => '', :stderr => '', :exit_signal => nil, :exit_status => 0 })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with("grep -q 'export VIRTUAL_ENV' /foo/bar/bin/activate").and_return(res)
      expect(v.virtualenv?).to eq true
    end
    it 'returns false with missing pip' do
      v = virtualenv('/foo/bar')
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/pip', 'owner').and_return(false)
      expect(v.virtualenv?).to eq false
    end
    it 'returns false with missing python' do
      v = virtualenv('/foo/bar')
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/pip', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/python', 'owner').and_return(false)
      expect(v.virtualenv?).to eq false
    end
    it 'returns false with missing activate' do
      v = virtualenv('/foo/bar')
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/pip', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/python', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_readable).once.ordered.with('/foo/bar/bin/activate', 'owner').and_return(false)
      expect(v.virtualenv?).to eq false
    end
    it 'returns false with invalid activate' do
      v = virtualenv('/foo/bar')
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/pip', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_executable).once.ordered.with('/foo/bar/bin/python', 'owner').and_return(true)
      expect(v.instance_variable_get(:@runner)).to receive(:check_file_is_readable).once.ordered.with('/foo/bar/bin/activate', 'owner').and_return(true)
      res = Specinfra::CommandResult.new({:stdout => '', :stderr => '', :exit_signal => nil, :exit_status => 254 })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with("grep -q 'export VIRTUAL_ENV' /foo/bar/bin/activate").and_return(res)
      expect(v.virtualenv?).to eq false
    end
  end
  context '#pip_version' do
    it 'returns the pip version stdout' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => 'pip 1.5.4 from /foo/bar/lib/python2.7/site-packages (python 2.7)',
                                           :stderr => '',
                                           :exit_signal => nil,
                                           :exit_status => 0
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/pip --version').and_return(res)
      expect(v.pip_version).to eq '1.5.4'
    end
    it 'returns an empty string on error' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => '',
                                           :stderr => 'Some Error',
                                           :exit_signal => nil,
                                           :exit_status => 100
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/pip --version').and_return(res)
      expect(v.pip_version).to eq ''
    end
  end
  context '#python_version' do
    it 'returns the python version stderr if used (python<3)' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => '',
                                           :stderr => 'Python 2.7.9',
                                           :exit_signal => nil,
                                           :exit_status => 0
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/python --version').and_return(res)
      expect(v.python_version).to eq '2.7.9'
    end
    it 'returns the python version stdout if used (python3+)' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => 'Python 3.4.2',
                                           :stderr => '',
                                           :exit_signal => nil,
                                           :exit_status => 0
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/python --version').and_return(res)
      expect(v.python_version).to eq '3.4.2'
    end
    it 'returns an empty string on error' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => '',
                                           :stderr => 'Some Error',
                                           :exit_signal => nil,
                                           :exit_status => 100
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/python --version').and_return(res)
      expect(v.python_version).to eq ''
    end
  end
  context '#pip_freeze' do
    it 'returns a hash of requirements' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => "foo==1\nbar==2",
                                           :stderr => '',
                                           :exit_signal => nil,
                                           :exit_status => 0
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/pip freeze').and_return(res)
      expected = { "foo" => "1", "bar" => "2" }
      expect(v.pip_freeze).to eq expected
    end
    it 'returns an empty hash on error' do
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => '',
                                           :stderr => '/foo/bar/bin/python3: error while loading shared libraries: libpython3.3m.so.1.0: cannot open shared object file: No such file or directory',
                                           :exit_signal => nil,
                                           :exit_status => 127
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/pip freeze').and_return(res)
      expected = {}
      expect(v.pip_freeze).to eq expected
    end
    it 'handles various requirements forms' do
      freeze_output = <<-eos
BeautifulSoup==3.2.1
PyYAML==3.11
Pygments==1.6
RBTools==0.6
Unidecode==0.04.14
certifi==14.05.14
click==3.3
django-auth-ldap==1.1.4
py==1.4.26
pytz==2013.9
pytz==2014.10
six==1.3.0
zope.interface==4.1.2
eos
      expected = {
        'BeautifulSoup' => '3.2.1',
        'PyYAML' => '3.11',
        'Pygments' => '1.6',
        'RBTools' => '0.6',
        'Unidecode' => '0.04.14',
        'certifi' => '14.05.14',
        'click' => '3.3',
        'django-auth-ldap' => '1.1.4',
        'py' => '1.4.26',
        'pytz' => '2013.9',
        'pytz' => '2014.10',
        'six' => '1.3.0',
        'zope.interface' => '4.1.2',
      }
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => freeze_output,
                                           :stderr => '',
                                           :exit_signal => nil,
                                           :exit_status => 0
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/pip freeze').and_return(res)
      expect(v.pip_freeze).to eq expected
    end
    it 'handles editable requirements' do
      freeze_output = <<-eos
-e git+git@github.com:coxmediagroup/troposphere.git@30d830e1554191a3e2bbb48ecbfddc33930b3ca5#egg=troposphere-origin/AUTO-1017
-e git+git@github.com:jantman/nodemeister.git@ecfd2c04f516b1ea022c55ce4372976055a39e5f#egg=nodemeister-master
-e git+ssh://vcs.ddtc.cmgdigital.com/git-repos/cm.git@e1c85a7a0cf8f5676fb89f35f43e40545e1719a3#egg=cm-AUTO-817
eos
      expected = {
        '-e git+git@github.com:coxmediagroup/troposphere.git@30d830e1554191a3e2bbb48ecbfddc33930b3ca5#egg=troposphere-origin/AUTO-1017' => '',
        '-e git+git@github.com:jantman/nodemeister.git@ecfd2c04f516b1ea022c55ce4372976055a39e5f#egg=nodemeister-master' => '',
        '-e git+ssh://vcs.ddtc.cmgdigital.com/git-repos/cm.git@e1c85a7a0cf8f5676fb89f35f43e40545e1719a3#egg=cm-AUTO-817' => ''
      }
      v = virtualenv('/foo/bar')
      res = Specinfra::CommandResult.new({
                                           :stdout => freeze_output,
                                           :stderr => '',
                                           :exit_signal => nil,
                                           :exit_status => 0
                                         })
      expect(v.instance_variable_get(:@runner)).to receive(:run_command).once.ordered.with('/foo/bar/bin/pip freeze').and_return(res)
      expect(v.pip_freeze).to eq expected
    end
  end
end

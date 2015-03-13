require 'spec_helper'
require 'serverspec_extended_types/http_get'

describe 'Serverspec::Type.bitlbee' do
  it 'instantiates the class with the correct parameters' do
    expect(Serverspec::Type::Bitlbee).to receive(:new).with(1, 'mynick', 'mypass', false)
    bitlbee(1, 'mynick', 'mypass')
  end
  it 'returns the new object' do
    expect(Serverspec::Type::Bitlbee).to receive(:new).and_return("foo")
    expect(bitlbee(1, 'foo', 'bar')).to eq "foo"
  end
end
describe 'Serverspec::Type::Bitlbee' do
  context '#initialize' do
    it 'sets instance variables' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@port)).to eq 1
      expect(x.instance_variable_get(:@host)).to eq 'myhost'
      expect(x.instance_variable_get(:@nick)).to eq 'foo'
      expect(x.instance_variable_get(:@password)).to eq 'bar'
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@version_str)).to eq ''
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@started)).to eq false
      expect(x.instance_variable_get(:@use_ssl)).to eq false
    end
    it 'sets use_ssl instance variable' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      x = bitlbee(1, 'foo', 'bar', use_ssl=true)
      expect(x.instance_variable_get(:@use_ssl)).to eq true
    end
  end
  context 'start' do
    it 'calls connect_ssl if use_ssl=true' do
      x = bitlbee(1, 'foo', 'bar', use_ssl=true)
      expect(x).to receive(:connect_ssl).once
      expect(x).to_not receive(:connect)
      x.start
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@started)).to eq true
    end
    it 'calls connect if use_ssl=false' do
      x = bitlbee(1, 'foo', 'bar')
      expect(x).to receive(:connect).once
      expect(x).to_not receive(:connect_ssl)
      x.start
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@started)).to eq true
    end
    it 'runs with a timeout' do
      x = bitlbee(1, 'foo', 'bar')
      expect(Timeout).to receive(:timeout).with(10)
      x.start
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@started)).to eq true
      expect(x.timed_out?).to eq false
    end
    it 'sets timed_out_status on timeout' do
      x = bitlbee(1, 'foo', 'bar')
      expect(Timeout).to receive(:timeout).with(10).and_raise(Timeout::Error)
      x.start
      expect(x.instance_variable_get(:@timed_out_status)).to eq true
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@started)).to eq true
      expect(x.timed_out?).to eq true
      expect(x.connectable?).to eq false
    end
    it 'sets connected_status on ECONNREFUSED' do
      x = bitlbee(1, 'foo', 'bar')
      expect(x).to receive(:connect).and_raise(Errno::ECONNREFUSED)
      x.start
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@started)).to eq true
      expect(x.timed_out?).to eq false
      expect(x.connectable?).to eq false
    end
  end
  context '#connect_ssl' do
    it 'calls communicate' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      sock_dbl = double
      expect(TCPSocket).to receive(:open).with('myhost', 1).and_return(sock_dbl)
      sslctx_dbl = double
      expect(OpenSSL::SSL::SSLContext).to receive(:new).and_return(sslctx_dbl)
      expect(sslctx_dbl).to receive(:set_params).with(verify_mode: OpenSSL::SSL::VERIFY_NONE).ordered
      sslsock_dbl = double
      expect(sslsock_dbl).to receive(:sync_close=).ordered.with(true)
      expect(sslsock_dbl).to receive(:connect).ordered
      expect(sslsock_dbl).to receive(:puts).ordered.with("communicate")
      expect(sslsock_dbl).to receive(:puts).ordered.with("QUIT :\"outta here\"\n")
      expect(sslsock_dbl).to receive(:close).ordered
      expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(sock_dbl, sslctx_dbl).and_return(sslsock_dbl)
      #expect_any_instance_of(Serverspec::Type::Bitlbee).to receive(:communicate)
      x = bitlbee(1, 'foo', 'bar')
      x.stub(:communicate) do
        x.instance_variable_get(:@socket).puts("communicate")
      end
      x.connect_ssl
      expect(x.instance_variable_get(:@socket)).to eq sslsock_dbl
    end
  end
  context '#connect' do
    it 'calls communicate' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      sock_dbl = double
      expect(TCPSocket).to receive(:open).with('myhost', 1).and_return(sock_dbl)
      expect(sock_dbl).to receive(:puts).ordered.with("communicate")
      expect(sock_dbl).to receive(:puts).ordered.with("QUIT :\"outta here\"\n")
      expect(sock_dbl).to receive(:close).ordered
      x = bitlbee(1, 'foo', 'bar')
      x.stub(:communicate) do
        x.instance_variable_get(:@socket).puts("communicate")
      end
      x.connect
      expect(x.instance_variable_get(:@socket)).to eq sock_dbl
    end
  end
  context '#communicate' do
    it 'logs in' do
      x = bitlbee(1, 'foo', 'bar')
      sock = double
      x.instance_variable_set(:@socket, sock)
      x.instance_variable_set(:@started, true)
      expect(sock).to receive(:puts).ordered.with("PASS bar\n")
      expect(sock).to receive(:puts).ordered.with("NICK foo\n")
      expect(sock).to receive(:puts).ordered.with("USER foo foo servername :TestUser\n")
      expect(sock).to receive(:readpartial).ordered.with(1024).and_return("Welcome to the foo")
      expect(sock).to receive(:puts).ordered.with("MODE foo +i\n")
      expect(sock).to receive(:readpartial).ordered.with(1024).and_return("If you've never something something")
      expect(sock).to receive(:puts).ordered.with("PRIVMSG &bitlbee :identify bar\n")
      expect(sock).to receive(:readpartial).ordered.with(1024).and_return("PING servername")
      expect(sock).to receive(:puts).ordered.with(":servername PONG servername :servername\n")
      expect(sock).to receive(:readpartial).ordered.with(1024).and_return("MODE foo :\+i")
      expect(sock).to receive(:puts).ordered.with("PRIVMSG root :\001VERSION\001\n")
      expect(sock).to receive(:readpartial).ordered.with(1024).and_return("foo bar baz blam\n")
      expect(sock).to receive(:readpartial).ordered.with(1024).and_return("VERSION x.y.z\n")
      x.communicate
      expect(x.instance_variable_get(:@connected_status)).to eq true
      expect(x.version).to eq 'x.y.z'
      expect(x.connectable?).to eq true
      expect(x.timed_out?).to eq false
    end
  end
  context '#timed_out?' do
    it 'calls start if not started' do
      x = bitlbee(1, 'foo', 'bar')
      expect(x).to receive(:start).once
      expect(x.timed_out?).to eq false
    end
    it 'doesnt call start if started' do
      x = bitlbee(1, 'foo', 'bar')
      x.instance_variable_set(:@started, true)
      expect(x).to_not receive(:start)
      expect(x.timed_out?).to eq false
    end
  end
  context '#connectable?' do
    it 'calls start if not started' do
      x = bitlbee(1, 'foo', 'bar')
      expect(x).to receive(:start).once
      expect(x.connectable?).to eq false
    end
    it 'doesnt call start if started' do
      x = bitlbee(1, 'foo', 'bar')
      x.instance_variable_set(:@started, true)
      expect(x).to_not receive(:start)
      expect(x.connectable?).to eq false
    end
  end
  context '#version?' do
    it 'calls start if not started' do
      x = bitlbee(1, 'foo', 'bar')
      expect(x).to receive(:start).once
      expect(x.version).to eq ""
    end
    it 'doesnt call start if started' do
      x = bitlbee(1, 'foo', 'bar')
      x.instance_variable_set(:@started, true)
      expect(x).to_not receive(:start)
      expect(x.version).to eq ""
    end
  end
end

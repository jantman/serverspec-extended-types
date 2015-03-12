require 'spec_helper'
require 'serverspec_extended_types/http_get'

describe 'Serverspec::Type.bitlbee' do
  it 'instantiates the class with the correct parameters' do
    expect(Serverspec::Type::Bitlbee).to receive(:new).with(1, 'mynick', 'mypass')
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
      expect_any_instance_of(Serverspec::Type::Bitlbee).to receive(:connect).once
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@port)).to eq 1
      expect(x.instance_variable_get(:@host)).to eq 'myhost'
      expect(x.instance_variable_get(:@nick)).to eq 'foo'
      expect(x.instance_variable_get(:@password)).to eq 'bar'
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.instance_variable_get(:@version_str)).to eq ''
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
    end
    it 'calls connect' do
      expect_any_instance_of(Serverspec::Type::Bitlbee).to receive(:connect).once
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
    end
    it 'runs with a timeout' do
      expect(Timeout).to receive(:timeout).with(10)
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
    end
    it 'sets timed_out_status on timeout' do
      expect(Timeout).to receive(:timeout).with(10).and_raise(Timeout::Error)
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@timed_out_status)).to eq true
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.timed_out?).to eq true
    end
    it 'sets connected_status on ECONNREFUSED' do
      expect_any_instance_of(Serverspec::Type::Bitlbee).to receive(:connect).and_raise(Errno::ECONNREFUSED)
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@timed_out_status)).to eq false
      expect(x.instance_variable_get(:@connected_status)).to eq false
      expect(x.timed_out?).to eq false
      expect(x.connectable?).to eq false
    end
  end
  context '#connect' do
    it 'calls communicate' do
      stub_const('ENV', ENV.to_hash.merge('TARGET_HOST' => 'myhost'))
      Serverspec::Type::Bitlbee.stub(:communicate) do
        @socket.puts("communicate")
      end
      sock_dbl = double
      expect(TCPSocket).to receive(:open).with('myhost', 1).and_return(sock_dbl)
      sslctx_dbl = double
      expect(OpenSSL::SSL::SSLContext).to receive(:new).and_return(sslctx_dbl)
      expect(sslctx_dbl).to receive(:set_params).with(verify_mode: OpenSSL::SSL::VERIFY_NONE).ordered
      sslsock_dbl = double
      expect(sslsock_dbl).to receive(:sync_close=).ordered.with(true)
      expect(sslsock_dbl).to receive(:connect).ordered
      expect(sslsock_dbl).to receive(:puts).ordered.with("QUIT :\"outta here\"\n")
      expect(sslsock_dbl).to receive(:close).ordered
      expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(sock_dbl, sslctx_dbl).and_return(sslsock_dbl)
      #expect_any_instance_of(Serverspec::Type::Bitlbee).to receive(:communicate)
      x = bitlbee(1, 'foo', 'bar')
      expect(x.instance_variable_get(:@socket)).to eq sslsock_dbl
    end
  end
end

require 'spec_helper'

OpenStack::Config = {
  user: 'TestUser',
  password: 'vD5UPlUZsGf54WR7k3mR',
  authtenant_name: 'test_tenant',
  auth_url: 'http://servers.api.openstack.org:15000/v2.0/',
  metering_service_path: '/v2'
}

RSpec.describe OpenStack::Connector do

  before do
    stub_request(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').
        with(:body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'}).
        to_return(:status => 200, :body => auth_token_response, :headers => {})
    stub_request(:get, 'http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/extensions').
        with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => 'OpenStack Ruby API 1.2', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(:status => 200, :body => "{\"extensions\":[{\"alias\":\"os-simple-tenant-usage\"}]}", :headers => {})
    stub_request(:get, 'http://servers.api.openstack.org:8777/v2/meters/bandwidth/statistics').
        with(headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => 'OpenStack Ruby API 1.2', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(status: 200, :body => bandwidth_response, :headers => {})
    @start, @end = (Time.now - 3600), Time.now
    stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
        with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => 'OpenStack Ruby API 1.2', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(:status => 200, :body => simple_tenant_usage_response, :headers => {})
    stub_request(:get, "http://servers.api.openstack.org:35357/v2.0/tenants").
        with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'User-Agent'=>'OpenStack Ruby API 1.2', 'X-Auth-Token'=>'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token'=>'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(:status => 200, :body => tenants_response, :headers => {})
    stub_request(:get, "http://servers.api.openstack.org:35357/v2.0/tenants/testtenantid").
        with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'User-Agent'=>'OpenStack Ruby API 1.2', 'X-Auth-Token'=>'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token'=>'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(:status => 200, :body => tenant_response, :headers => {})
  end

  let(:connector) {OpenStack::Connector.new}

  context '#bandwidth' do

    it 'authorizes #bandwidth first' do
      connector.metering.accumulated_bandwidth
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests bandwidth' do
      connector.metering.accumulated_bandwidth
      expect(WebMock).to have_requested(:get, 'http://servers.api.openstack.org:8777/v2/meters/bandwidth/statistics').
                             with(headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => 'OpenStack Ruby API 1.2', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.metering.accumulated_bandwidth).to eq(bandwidths_response_ary)
    end
  end

  context '#simple_tenant_usage' do
    it 'authorizes #simple_tenant_usage first' do
      connector.compute.simple_tenant_usage @start, @end
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end


    it 'requests simple-tenant-usages' do
      connector.compute.simple_tenant_usage @start, @end
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => 'OpenStack Ruby API 1.2', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.compute.simple_tenant_usage(@start, @end)).to eq(simple_tenant_usages_response)
    end
  end

  context '#tenants' do
    it 'requests tenants from keystone' do
      connector.identity.tenants
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:35357/v2.0/tenants").
                             with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'User-Agent'=>'OpenStack Ruby API 1.2', 'X-Auth-Token'=>'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token'=>'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.identity.tenants).to eq(tenants_response_ary)
    end

  end

  context '#tenant' do
    it 'requests tenants from keystone' do
      connector.identity.tenant('testtenantid')
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:35357/v2.0/tenants/testtenantid").
                             with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'User-Agent'=>'OpenStack Ruby API 1.2', 'X-Auth-Token'=>'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token'=>'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.identity.tenant('testtenantid')).to eq(tenant_response_hash)
    end

  end

end
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
        with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(:status => 200, :body => "{\"extensions\":[{\"alias\":\"os-simple-tenant-usage\"},{\"alias\":\"os-security-groups\"}]}", :headers => {})

    @start, @end = (Time.now - 3600), Time.now
  end

  let(:connector) { OpenStack::Connector.new }

  context '#bandwidth' do

    before do
      stub_request(:get, 'http://servers.api.openstack.org:8777/v2/meters/bandwidth/statistics').
          with(headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(status: 200, :body => bandwidth_response, :headers => {})
      stub_request(:get, "http://servers.api.openstack.org:8777/v2/meters/bandwidth?q.field=timestamp&q.op=ge&q.type=&q.value=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => bandwidth_response, :headers => {})

    end

    it 'authorizes #bandwidth first' do
      connector.metering.accumulated_bandwidth
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests bandwidth' do
      connector.metering.accumulated_bandwidth
      expect(WebMock).to have_requested(:get, 'http://servers.api.openstack.org:8777/v2/meters/bandwidth/statistics').
                             with(headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'requests bandwidth sample-list' do
      connector.metering.bandwidth start: @start
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8777/v2/meters/bandwidth?q.field=timestamp&q.op=ge&q.type=&q.value=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
                             with(headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.metering.bandwidth(start: @start)).to eq(bandwidths_response_ary)
    end

  end

  context '#list_servers_detail' do


    before do
      stub_request(:get, /http:\/\/servers\.api\.openstack\.org:8774\/v2\/fc394f2ab2df4114bde39905f800dc57\/servers\/detail(?:\?.+)?/).
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => servers_details_response, :headers => {})
    end

    it 'authorizes #list_servers_detail first' do
      connector.compute.list_servers_detail
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests servers/detail' do
      connector.compute.list_servers_detail
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/detail").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    {'limit=5' => {limit: 5}, 'all_tenants=1&host=node6' => {all_tenants: 1, host: 'node6'}}.each do |path, params|

      it "requests servers/detail with params #{path}" do
        connector.compute.list_servers_detail(params)
        expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/detail?#{path}").
                               with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
      end
    end


    it 'parses the response' do
      expect(connector.compute.list_servers_detail).to eq(expected_servers_details_ary)
    end

  end

  context '#list_networks' do


    before do
      stub_request(:get, 'http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-networks').
        with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection'=>'Keep-Alive', 'User-Agent'=>'OpenStack Ruby API 1.5.3', 'X-Auth-Token'=>'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token'=>'aaaaa-bbbbb-ccccc-dddd'}).
        to_return(:status => 200, :body => '{"networks": [{"bridge": null, "vpn_public_port": null, "dhcp_start": null, "bridge_interface": null, "updated_at": null, "id": "231ad16d-1466-4d8a-8191-4f0c5e1d9398", "cidr_v6": null, "deleted_at": null, "gateway": null, "rxtx_base": null, "label": "hitnet", "priority": null, "project_id": null, "vpn_private_address": null, "deleted": null, "vlan": null, "broadcast": null, "netmask": null, "injected": null, "cidr": null, "vpn_public_address": null, "multi_host": null, "dns2": null, "created_at": null, "host": null, "gateway_v6": null, "netmask_v6": null, "dns1": null}]}', :headers => {})
    end

    it 'authorizes #networks first' do
      connector.compute.networks
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                           :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                           :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests networks' do
      connector.compute.networks
      expect(WebMock).to have_requested(:get, 'http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-networks').
                           with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.compute.networks).to eq([{:bridge=>nil, :vpn_public_port=>nil, :dhcp_start=>nil, :bridge_interface=>nil, :updated_at=>nil, :id=>'231ad16d-1466-4d8a-8191-4f0c5e1d9398', :cidr_v6=>nil, :deleted_at=>nil, :gateway=>nil, :rxtx_base=>nil, :label=>"hitnet", :priority=>nil, :project_id=>nil, :vpn_private_address=>nil, :deleted=>nil, :vlan=>nil, :broadcast=>nil, :netmask=>nil, :injected=>nil, :cidr=>nil, :vpn_public_address=>nil, :multi_host=>nil, :dns2=>nil, :created_at=>nil, :host=>nil, :gateway_v6=>nil, :netmask_v6=>nil, :dns1=>nil}])
    end

  end

  context '#migration' do
    before do
      stub_request(:post, 'http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/0443e9a1254044d8b99f35eace132080/action').
          with(
              headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'},
              body: '{"migrate":null}'
          ).
          to_return(:status => 202, :body => nil, :headers => {})
      stub_request(:post, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/0443e9a1254044d8b99f35eace132080/action").
          with(:body => "{\"os-migrateLive\":{\"host\":null,\"block_migration\":false,\"disk_over_commit\":false}}",
               :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => nil, :headers => {})
    end

    it 'authorizes migration first' do
      connector.compute.migrate('0443e9a1254044d8b99f35eace132080')
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests migration' do
      connector.compute.migrate('0443e9a1254044d8b99f35eace132080')
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/0443e9a1254044d8b99f35eace132080/action').with(
                             headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'},
                             body: '{"migrate":null}')
    end

    it 'requests live migration' do
      connector.compute.live_migrate('0443e9a1254044d8b99f35eace132080')
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/0443e9a1254044d8b99f35eace132080/action').with(
                             headers: {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'},
                             body: '{"os-migrateLive":{"host":null,"block_migration":false,"disk_over_commit":false}}')
    end

  end

  context '#simple_tenant_usage' do

    before do
      stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => simple_tenants_usage_response, :headers => {})
      stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => simple_tenants_usage_response, :headers => {})
      stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage/fc394f2ab2df4114bde39905f800dc58?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => simple_tenant_usage_response('fc394f2ab2df4114bde39905f800dc58'), :headers => {})
    end

    it 'authorizes #simple_tenant_usage first' do
      connector.compute.simple_tenant_usage @start, @end
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end


    it 'requests simple-tenant-usages' do
      connector.compute.simple_tenant_usage @start, @end
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.compute.simple_tenant_usage(@start, @end)).to eq(simple_tenants_usages_response)
    end

    it 'authorizes #simple_tenant_usage for tenant fc394f2ab2df4114bde39905f800dc58 first' do
      connector.compute.simple_tenant_usage @start, @end, 'fc394f2ab2df4114bde39905f800dc58'
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests simple-tenant-usages for tenant fc394f2ab2df4114bde39905f800dc58' do
      connector.compute.simple_tenant_usage @start, @end, 'fc394f2ab2df4114bde39905f800dc58'
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage/fc394f2ab2df4114bde39905f800dc58?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response for tenant fc394f2ab2df4114bde39905f800dc58' do
      expect(connector.compute.simple_tenant_usage(@start, @end, 'fc394f2ab2df4114bde39905f800dc58')).to eq(simple_tenant_usages_response('fc394f2ab2df4114bde39905f800dc58'))
    end

  end

  context '#security_groups' do
    before do
      WebMock.stub_request(:put, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-security-groups/security_group_id").
          with(:body => "{\"security_group\":{\"name\":\"outdatedSecGroup\",\"description\":\"this describes the new sec. group\"}}",
               :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => '{"security_group":{"id":"security_group_id","description":"some description","name":"outdatedSecGroup","rules":[],"tenant_id":"fc394f2ab2df4114bde39905f800dc58"}}', :headers => {})
    end

    it 'authorizes securit_groups update first' do
      connector.compute.update_security_group 'security_group_id', 'outdatedSecGroup', 'this describes the new sec. group'
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:15000/v2.0/tokens').with(
                             :body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"test_tenant\"}}",
                             :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests update security groups' do
      connector.compute.update_security_group 'security_group_id', 'outdatedSecGroup', 'this describes the new sec. group'
      expect(WebMock).to have_requested(:put, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-security-groups/security_group_id").
                             with(:body => "{\"security_group\":{\"name\":\"outdatedSecGroup\",\"description\":\"this describes the new sec. group\"}}",
                                  :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response for security group update' do
      expect(connector.compute.update_security_group('security_group_id', 'outdatedSecGroup', 'this describes the new sec. group')).to eq('security_group_id' => {id: 'security_group_id', description: 'some description', name: 'outdatedSecGroup', rules: [], tenant_id: 'fc394f2ab2df4114bde39905f800dc58'})
    end

  end

  context '#tenants' do

    before do
      stub_request(:get, "http://servers.api.openstack.org:35357/v2.0/tenants").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => tenants_response, :headers => {})
    end

    it 'requests tenants from keystone' do
      connector.identity.tenants
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:35357/v2.0/tenants").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.identity.tenants).to eq(tenants_response_ary)
    end

  end

  context '#tenant' do

    before do
      stub_request(:get, "http://servers.api.openstack.org:35357/v2.0/tenants/testtenantid").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => tenant_response, :headers => {})
    end

    it 'requests tenants from keystone' do
      connector.identity.tenant('testtenantid')
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:35357/v2.0/tenants/testtenantid").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.identity.tenant('testtenantid')).to eq(tenant_response_hash)
    end

  end

  context '#endpoints' do
    before do
      stub_request(:get, "http://servers.api.openstack.org:35357/v2.0/endpoints").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => endpoints_response, :headers => {})
    end

    it 'requests endpoints from keystone' do
      connector.identity.endpoints
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:35357/v2.0/endpoints").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.identity.endpoints).to eq(endpoints_response_ary)
    end

  end

  context '#object-store container list' do

    let(:connector) { OpenStack::Connector.new 'object-store-tenant' }


    before do
      stub_request(:post, "http://servers.api.openstack.org:15000/v2.0/tokens").
          with(:body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"object-store-tenant\"}}",
               :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'}).
          to_return(:status => 200, :body => auth_token_response, :headers => {})
      stub_request(:get, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57?format=json").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => containers_response, :headers => {})
    end

    it 'authenticates with special tenant' do
      connector.object_store.containers
      expect(WebMock).to have_requested(:post, "http://servers.api.openstack.org:15000/v2.0/tokens").with(:body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"object-store-tenant\"}}",
                                                                                                          :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'lists containers' do
      connector.object_store.containers
    end

    it 'parses the response' do
      expect(connector.object_store.containers).to eq(containers_response_ary)
    end

  end

  context '#object-store acl' do
    let(:connector) { OpenStack::Connector.new 'object-store-tenant' }

    before do
      stub_request(:post, "http://servers.api.openstack.org:15000/v2.0/tokens").
          with(:body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"object-store-tenant\"}}",
               :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'}).
          to_return(:status => 200, :body => auth_token_response, :headers => {})
      stub_request(:head, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57/test").
          with(:headers => {'Accept' => 'application/json', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => "", :headers => {'x-container-object-count' => '1', 'vary' => 'Accept-Encoding', 'server' => 'Apache', 'x-container-bytes-used-actual' => '3465216', 'x-container-bytes-used' => '3461240', 'x-container-write' => '.r:example.com,swift.example.com', 'x-container-read' => '.r:*', 'date' => 'Thu, 23 Oct 2014 03:35:09 GMT', 'content-type' => 'text/plain; charset=utf-8'})
      stub_request(:post, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57/test").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Container-Read' => '.rlistings', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => "", :headers => {})
      stub_request(:post, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57/test").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Container-Write' => '.r:*', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => "", :headers => {})
    end

    it 'authenticates with special tenant' do
      container = connector.object_store.container('test')
      container.read_acl
      expect(WebMock).to have_requested(:post, "http://servers.api.openstack.org:15000/v2.0/tokens").with(:body => "{\"auth\":{\"passwordCredentials\":{\"username\":\"TestUser\",\"password\":\"vD5UPlUZsGf54WR7k3mR\"},\"tenantName\":\"object-store-tenant\"}}",
                                                                                                          :headers => {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby'})
    end

    it 'requests container-data' do
      connector.object_store.container('test')
      expect(WebMock).to have_requested(:head, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57/test").with(:headers => {'Accept' => 'application/json', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'responds to read_acl' do
      container = connector.object_store.container('test')
      expect(container.read_acl).to eq('.r:*')
    end

    it 'responds to write_acl' do
      container = connector.object_store.container('test')
      expect(container.write_acl).to eq('.r:example.com,swift.example.com')
    end

    it 'sets new read_acl' do
      container = connector.object_store.container('test')
      container.read_acl = '.rlistings'
      expect(WebMock).to have_requested(:post, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57/test").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Container-Read' => '.rlistings', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'sets new write_acl' do
      container = connector.object_store.container('test')
      container.write_acl = '.r:*'
      expect(WebMock).to have_requested(:post, "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57/test").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Container-Write' => '.r:*', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

  end


  context '#network' do

    before do
      stub_request(:post, "http://servers.api.openstack.org:9696/v2.0/metering/metering-labels").
          with(:body => "{\"metering_label\":{\"name\":\"ingress\",\"tenant_id\":\"test#tenant\",\"description\":\"ingress for test_tenant\"}}",
               :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => create_metering_label_response, :headers => {})
      stub_request(:post, "http://servers.api.openstack.org:9696/v2.0/metering/metering-label-rules").
          with(:body => "{\"metering_label_rule\":{\"metering_label_id\":\"test#label\",\"remote_ip_prefix\":\"0.0.0.0/24\"}}",
               :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => create_metering_label_rule_response, :headers => {})
    end

    it 'creates a new metering label' do
      connector.network.create_metering_label('ingress', tenant_id: 'test#tenant', description: "ingress for test_tenant")
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:9696/v2.0/metering/metering-labels').
                             with(:body => "{\"metering_label\":{\"name\":\"ingress\",\"tenant_id\":\"test#tenant\",\"description\":\"ingress for test_tenant\"}}",
                                  :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    it 'parses the response' do
      expect(connector.network.create_metering_label('ingress', tenant_id: 'test#tenant', description: "ingress for test_tenant")).to eq(create_metering_hash)
    end

    it 'creates a new metering label rule' do
      connector.network.create_metering_label_rule('test#label', '0.0.0.0/24')
      expect(WebMock).to have_requested(:post, 'http://servers.api.openstack.org:9696/v2.0/metering/metering-label-rules').
                             with(:body => "{\"metering_label_rule\":{\"metering_label_id\":\"test#label\",\"remote_ip_prefix\":\"0.0.0.0/24\"}}",
                                  :headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end
  end

end

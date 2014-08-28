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
        to_return(:status => 200, :body => "{\"extensions\":[{\"alias\":\"os-simple-tenant-usage\"}]}", :headers => {})

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

    def expected_servers_details_ary
      [
          {
              accessIPv4: "",
              accessIPv6: "",
              addresses: {
                  public: [],
                  private: [
                      {
                          addr: "192.168.0.3",
                          version: 4,
                          :"OS-EXT-IPS-MAC:mac_addr" => "00:0c:29:e1:42:90"
                      }
                  ]
              },
              created: "2013-02-07T18:40:59Z",
              flavor: {
                  id: "1",
                  links: [
                      {
                          href: "http://openstack.example.com/openstack/flavors/1",
                          rel: "bookmark"
                      }
                  ]
              },
              hostId: "fe866a4962fe3bdb6c2db9c8f7dcdb9555aca73387e72b5cb9c45bd3",
              id: "76908712-653a-4d16-807e-d89d41435d24",
              image: {
                  id: "70a599e0-31e7-49b7-b260-868f441e862b",
                  links: [
                      {
                          href: "http://openstack.example.com/openstack/images/70a599e0-31e7-49b7-b260-868f441e862b",
                          rel: "bookmark"
                      }
                  ]
              },
              links: [
                  {
                      href: "http://openstack.example.com/v2/openstack/servers/76908712-653a-4d16-807e-d89d41435d24",
                      rel: "self"
                  },
                  {
                      href: "http://openstack.example.com/openstack/servers/76908712-653a-4d16-807e-d89d41435d24",
                      rel: "bookmark"
                  }
              ],
              metadata: {
                  :"My Server Name" => "Apache1"
              },
              name: "new-server-test",
              progress: 0,
              status: "ACTIVE",
              tenant_id: "openstack",
              updated: "2013-02-07T18:40:59Z",
              user_id: "fake"
          }
      ]
    end


    before do
      stub_request(:get, /http:\/\/servers\.api\.openstack\.org:8774\/v2\/fc394f2ab2df4114bde39905f800dc57\/servers\/detail(?:\?.+)?/).
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => 'OpenStack Ruby API 1.2.3', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
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
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => 'OpenStack Ruby API 1.2.3', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
    end

    {'limit=5' => {limit: 5}, 'all_tenants=1&host=node6' => {all_tenants: 1, host: 'node6'}}.each do |path, params|

      it "requests servers/detail with params #{path}" do
        connector.compute.list_servers_detail(params)
        expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/servers/detail?#{path}").
                               with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'User-Agent' => 'OpenStack Ruby API 1.2.3', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
      end
    end


    it 'parses the response' do
      expect(connector.compute.list_servers_detail).to eq(expected_servers_details_ary)
    end

  end

  context '#simple_tenant_usage' do

    before do
      stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => simple_tenant_usage_response, :headers => {})
      stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => simple_tenant_usage_response, :headers => {})
      stub_request(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage/fc394f2ab2df4114bde39905f800dc58?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
          with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => 'OpenStack Ruby API 1.2.3', 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'}).
          to_return(:status => 200, :body => simple_tenant_usage_response, :headers => {})
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
      expect(connector.compute.simple_tenant_usage(@start, @end)).to eq(simple_tenant_usages_response)
    end

    it 'requests simple-tenant-usages for tenant fc394f2ab2df4114bde39905f800dc58' do
      connector.compute.simple_tenant_usage @start, @end, 'fc394f2ab2df4114bde39905f800dc58'
      expect(WebMock).to have_requested(:get, "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57/os-simple-tenant-usage/fc394f2ab2df4114bde39905f800dc58?end=#{@end.strftime('%Y-%m-%dT%H:%M:%S.%6N')}&start=#{@start.strftime('%Y-%m-%dT%H:%M:%S.%6N')}").
                             with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Connection' => 'Keep-Alive', 'Content-Type' => 'application/json', 'User-Agent' => "OpenStack Ruby API #{OpenStack::VERSION}", 'X-Auth-Token' => 'aaaaa-bbbbb-ccccc-dddd', 'X-Storage-Token' => 'aaaaa-bbbbb-ccccc-dddd'})
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
module OpenStackResponses

  def servers_details_ary
    [
        {
            accessIPv4: "",
            accessIPv6: "",
            addresses: {
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

  def servers_details_response
    {
        servers: servers_details_ary
    }.to_json
  end

  def tenant_response_hash
    {
        id: "1234",
        name: "ACME corp",
        description: "A description ...",
        enabled: true
    }
  end

  def tenant_response
    {
        tenant: tenant_response_hash
    }.to_json
  end

  def tenants_response_ary
    [
        {
            id: "1234",
            name: "ACME Corp",
            description: "A description ...",
            enabled: true
        },
        {
            id: "3456",
            name: "Iron Works",
            description: "A description ...",
            enabled: true
        }
    ]
  end

  def tenants_response
    {
        tenants: tenants_response_ary,
        tenants_links: []
    }.to_json
  end

  def endpoints_response_ary
    [
            {
                id: 1,
                tenantId: "1",
                region: "North",
                type: "compute",
                publicURL: "https://compute.north.public.com/v1",
                internalURL: "https://compute.north.internal.com/v1",
                adminURL: "https://compute.north.internal.com/v1",
                versionId: "1",
                versionInfo: "https://compute.north.public.com/v1/",
                versionList: "https://compute.north.public.com/"
            },
            {
                id: 2,
                tenantId: "1",
                region: "South",
                type: "compute",
                publicURL: "https://compute.north.public.com/v1",
                internalURL: "https://compute.north.internal.com/v1",
                adminURL: "https://compute.north.internal.com/v1",
                versionId: "1",
                versionInfo: "https://compute.north.public.com/v1/",
                versionList: "https://compute.north.public.com/"
            },
            {
                id: 3,
                tenantId: "1",
                region: "East",
                type: "compute",
                publicURL: "https://compute.north.public.com/v1",
                internalURL: "https://compute.north.internal.com/v1",
                adminURL: "https://compute.north.internal.com/v1",
                versionId: "1",
                versionInfo: "https://compute.north.public.com/v1/",
                versionList: "https://compute.north.public.com/"
            },
            {
                id: 4,
                tenantId: "1",
                region: "West",
                type: "compute",
                publicURL: "https://compute.north.public.com/v1",
                internalURL: "https://compute.north.internal.com/v1",
                adminURL: "https://compute.north.internal.com/v1",
                versionId: "1",
                versionInfo: "https://compute.north.public.com/v1/",
                versionList: "https://compute.north.public.com/"
            },
            {
                id: 5,
                tenantId: "1",
                region: "Global",
                type: "compute",
                publicURL: "https://compute.north.public.com/v1",
                internalURL: "https://compute.north.internal.com/v1",
                adminURL: "https://compute.north.internal.com/v1",
                versionId: "1",
                versionInfo: "https://compute.north.public.com/v1/",
                versionList: "https://compute.north.public.com/"
            }
        ]
  end

  def endpoints_response
    {
        endpoints: endpoints_response_ary,
        endpoints_links: []
    }.to_json
  end

  def simple_tenants_usages_response
    [
        {
            start: "2012-10-08T21:10:44.587336",
            stop: "2012-10-08T22:10:44.587336",
            tenant_id: "openstack",
            total_hours: 1.0,
            total_local_gb_usage: 1.0,
            total_memory_mb_usage: 512.0,
            total_vcpus_usage: 1.0
        }
    ]
  end

  def simple_tenant_usages_response(tenant_id)
    {
        :total_memory_mb_usage => 106496.0,
        :total_vcpus_usage => 52.0,
        :start => "2014-09-14T00:00:00.000000",
        :tenant_id => tenant_id,
        :stop => "2014-09-14T01:00:00.000000",
        :server_usages =>
            [
                {
                    :instance_id => "8f3761c6-ac2a-4bfb-bb77-e0e17f09f7d2",
                    :uptime => 2566220,
                    :started_at => "2014-08-19T20:40:39.000000",
                    :ended_at => nil,
                    :memory_mb => 2048,
                    :tenant_id => "474fcdd4d1c14fada4fa20444b00362e",
                    :state => "suspended",
                    :hours => 1.0,
                    :vcpus => 1,
                    :flavor => "m1.small",
                    :local_gb => 20,
                    :name => "test2"
                },
                {
                    :instance_id => "321cfe66-3687-40dc-b32e-421b6efa55ff",
                    :uptime => 2345139,
                    :started_at => "2014-08-22T10:05:20.000000",
                    :ended_at => nil,
                    :memory_mb => 2048,
                    :tenant_id => "474fcdd4d1c14fada4fa20444b00362e",
                    :state => "active",
                    :hours => 1.0,
                    :vcpus => 1,
                    :flavor => "m1.small",
                    :local_gb => 20,
                    :name => "test"
                }
            ]
    }
  end

  def create_metering_label_rule_hash
    {
        remote_ip_prefix: "10.0.1.0/24",
        direction: "ingress",
        metering_label_id: "e131d186-b02d-4c0b-83d5-0c0725c4f812",
        id: "00e13b58-b4f2-4579-9c9c-7ac94615f9ae",
        excluded: false
    }
  end

  def create_metering_label_rule_response
    {
        metering_label_rule: create_metering_label_rule_hash
    }.to_json
  end

  def create_metering_hash
    {
        tenant_id: "45345b0ee1ea477fac0f541b2cb79cd4",
        description: "description of label1",
        name: "label1",
        id: "bc91b832-8465-40a7-a5d8-ba87de442266"
    }
  end

  def create_metering_label_response
    {
        metering_label: create_metering_hash
    }.to_json
  end

  def simple_tenant_usage_response(tenant_id)
    {
        "tenant_usage" => simple_tenant_usages_response(tenant_id)
    }.to_json
  end

  def simple_tenants_usage_response
    {
        "tenant_usages" => simple_tenants_usages_response
    }.to_json
  end

  def bandwidths_response_ary
    [
        {:counter_name => "bandwidth",
         :user_id => nil,
         :resource_id => "6b704a3d-ff3a-027c-a1b9-ae237e15681a",
         :timestamp => "2014-08-22T14:10:54.092994",
         :recorded_at => "2014-08-22T14:10:57.382731",
         :message_id => "211297c4-2a06-027c-aab0-90e2ba551229",
         :source => "openstack",
         :counter_unit => "B",
         :counter_volume => 305.0,
         :project_id => "fc394f2ab2df4114bde39905f800dc57",
         :resource_metadata =>
             {:event_type => "l3.meter",
              :tenant_id => "fc394f2ab2df4114bde39905f800dc57",
              :first_update => "1408705999",
              :bytes => "305",
              :label_id => "112be531-7b7d-027c-90aa-a7016dd75643",
              :last_update => "1408716654",
              :host => "metering.node68",
              :time => "301",
              :pkts => "7"},
         :counter_type => "delta"},
        {:counter_name => "bandwidth",
         :user_id => nil,
         :resource_id => "6b704a3d-ff3a-027c-a1b9-ae237e15681a",
         :timestamp => "2014-08-22T14:10:54.087850",
         :recorded_at => "2014-08-22T14:10:54.740347",
         :message_id => "2111cd30-2a06-027c-aab0-90e2ba551229",
         :source => "openstack",
         :counter_unit => "B",
         :counter_volume => 23784.0,
         :project_id => "fc394f2ab2df4114bde39905f800dc57",
         :resource_metadata =>
             {:event_type => "l3.meter",
              :tenant_id => "fc394f2ab2df4114bde39905f800dc57",
              :first_update => "1408705999",
              :bytes => "23784",
              :label_id => "6b704a3d-ff3a-027c-a1b9-ae237e15681a",
              :last_update => "1408716654",
              :host => "metering.node68",
              :time => "301",
              :pkts => "566"},
         :counter_type => "delta"}
    ]
  end

  def bandwidth_response
    bandwidths_response_ary.to_json
  end

  def auth_token_response
    <<-RESP
{
    "access": {
        "token": {
            "issued_at": "2014-01-30T15:30:58.819584",
            "expires": "2014-01-31T15:30:58Z",
            "id": "aaaaa-bbbbb-ccccc-dddd",
            "tenant": {
                "description": null,
                "enabled": true,
                "id": "fc394f2ab2df4114bde39905f800dc57",
                "name": "demo"
            }
        },
        "serviceCatalog": [
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57",
                        "id": "2dad48f09e2a447a9bf852bcd93548ef",
                        "publicURL": "http://servers.api.openstack.org:8774/v2/fc394f2ab2df4114bde39905f800dc57"
                    }
                ],
                "endpoints_links": [],
                "type": "compute",
                "name": "nova"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:9696/",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:9696/",
                        "id": "97c526db8d7a4c88bbb8d68db1bdcdb8",
                        "publicURL": "http://servers.api.openstack.org:9696/"
                    }
                ],
                "endpoints_links": [],
                "type": "network",
                "name": "neutron"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8776/v2/fc394f2ab2df4114bde39905f800dc57",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8776/v2/fc394f2ab2df4114bde39905f800dc57",
                        "id": "93f86dfcbba143a39a33d0c2cd424870",
                        "publicURL": "http://servers.api.openstack.org:8776/v2/fc394f2ab2df4114bde39905f800dc57"
                    }
                ],
                "endpoints_links": [],
                "type": "volumev2",
                "name": "cinder"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8774/v3",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8774/v3",
                        "id": "3eb274b12b1d47b2abc536038d87339e",
                        "publicURL": "http://servers.api.openstack.org:8774/v3"
                    }
                ],
                "endpoints_links": [],
                "type": "computev3",
                "name": "nova"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8777",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8777",
                        "id": "102241636a2645c7bba4e2d06142aa15",
                        "publicURL": "http://servers.api.openstack.org:8777"
                    }
                ],
                "endpoints_links": [],
                "type": "metering",
                "name": "telemetry"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:9292",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:9292",
                        "id": "27d5749f36864c7d96bebf84a5ec9767",
                        "publicURL": "http://servers.api.openstack.org:9292"
                    }
                ],
                "endpoints_links": [],
                "type": "image",
                "name": "glance"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8776/v1/fc394f2ab2df4114bde39905f800dc57",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8776/v1/fc394f2ab2df4114bde39905f800dc57",
                        "id": "37c83a2157f944f1972e74658aa0b139",
                        "publicURL": "http://servers.api.openstack.org:8776/v1/fc394f2ab2df4114bde39905f800dc57"
                    }
                ],
                "endpoints_links": [],
                "type": "volume",
                "name": "cinder"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8773/services/Admin",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8773/services/Cloud",
                        "id": "289b59289d6048e2912b327e5d3240ca",
                        "publicURL": "http://servers.api.openstack.org:8773/services/Cloud"
                    }
                ],
                "endpoints_links": [],
                "type": "ec2",
                "name": "ec2"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:8080",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57",
                        "id": "16b76b5e5b7d48039a6e4cc3129545f3",
                        "publicURL": "http://servers.api.openstack.org:8080/v1/AUTH_fc394f2ab2df4114bde39905f800dc57"
                    }
                ],
                "endpoints_links": [],
                "type": "object-store",
                "name": "swift"
            },
            {
                "endpoints": [
                    {
                        "adminURL": "http://servers.api.openstack.org:35357/v2.0",
                        "region": "RegionOne",
                        "internalURL": "http://servers.api.openstack.org:15000/v2.0",
                        "id": "26af053673df4ef3a2340c4239e21ea2",
                        "publicURL": "http://servers.api.openstack.org:15000/v2.0"
                    }
                ],
                "endpoints_links": [],
                "type": "identity",
                "name": "keystone"
            }
        ],
        "user": {
            "username": "demo",
            "roles_links": [],
            "id": "9a6590b2ab024747bc2167c4e064d00d",
            "roles": [
                {
                    "name": "Member"
                },
                {
                    "name": "anotherrole"
                }
            ],
            "name": "demo"
        },
        "metadata": {
            "is_admin": 0,
            "roles": [
                "7598ac3c634d4c3da4b9126a5f67ca2b",
                "f95c0ab82d6045d9805033ee1fbc80d4"
            ]
        }
    }
}
    RESP
  end


end
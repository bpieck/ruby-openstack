module OpenStackResponses

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

  def simple_tenant_usages_response
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

  def simple_tenant_usage_response
    {
        "tenant_usages" => simple_tenant_usages_response
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
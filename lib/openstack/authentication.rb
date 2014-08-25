#============================
# OpenStack::Authentication
#============================

module OpenStack
  class Authentication

    # Performs an authentication to the OpenStack auth server.
    # If it succeeds, it sets the service_host, service_path, service_port,
    # service_scheme, authtoken, and authok variables on the connection.
    # If it fails, it raises an exception.

    def self.init(conn)
      if conn.auth_path =~ /.*v2.0\/?$/
        AuthV20.new(conn)
      else
        AuthV10.new(conn)
      end
    end

  end

  class Auth
    def start_server_connection(tries = connection.retries, time = 3)
      @server = Net::HTTP::Proxy(connection.proxy_host, connection.proxy_port).new(connection.auth_host, connection.auth_port)
      if connection.auth_scheme == 'https'
        @server.use_ssl = true
        @server.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @server.start
      @server
    rescue
      puts "Can't connect to the server: #{tries} tries  to reconnect" if connection.is_debug
      sleep time += 1
      retry unless (tries -= 1) <= 0
      raise OpenStack::Exception::Connection, "Unable to connect to  #{@server}"
    end
  end

  private

  class AuthV20 < Auth
    attr_reader :uri, :version, :connection

    def initialize(connection)
      @connection = connection
      set_identity_data
    end

    private

    def set_identity_data
      if request_successful?
        connection.authtoken = identity_data['access']['token']['id']
        unless implemented_services.include?(connection.service_type)
          raise OpenStack::Exception::NotImplemented.new("The requested service: \"#{connection.service_type}\" is not present " +
                                                             'in the returned service catalogue.', 501, "#{identity_data['access']['serviceCatalog']}")
        end
        identity_data['access']['serviceCatalog'].each do |service|
          set_region_list(service['endpoints'], service)
          if type_fits?(service)
            get_uri(service['endpoints'], service)
          end
        end
      else
        connection.authtoken = false
        raise OpenStack::Exception::Authentication, "Authentication failed with response code #{token_response.code}"
      end
    ensure
      @server.finish if @server.respond_to?(:started?) && @server.started?
    end

    def set_region_list(endpoints, service)
      endpoints.each do |endpoint|
        connection.regions_list[endpoint['region']] ||= []
        connection.regions_list[endpoint['region']] << {service: service['type'], versionId: endpoint['versionId']}
      end
    end

    def get_uri(endpoints, service)
      if connection.region
        uri_for_region(endpoints, connection.region)
      else
        @uri = URI.parse(endpoints.first['publicURL'])
      end
      if uri.nil?
        raise OpenStack::Exception::Authentication, "No API endpoint for region #{connection.region}"
      else
        #if already got one version of endpoints
        return false if @version && @version.to_f > get_version_from_response(service).to_f
        set_connection_attributes(uri, service)
      end
    end

    def uri_for_region(endpoints, region)
      endpoints.each do |ep|
        if ep['region'] and ep['region'].upcase == connection.region.upcase
          @uri = URI.parse(ep['publicURL'])
          break
        end
      end
    end

    def implemented_services
      @implemented_services ||= identity_data['access']['serviceCatalog'].inject([]) { |res, current| res << current['type'] }
    end

    def type_fits?(service)
      service['type'] == connection.service_type && (connection.service_name.nil? || service['name'] == connection.service_name)
    end

    def request_successful?
      token_response.code =~ /^20./
    end

    def identity_data
      @identity_data ||= JSON.parse(token_response.body)
    end

    def token_response
      @token_response ||= start_server_connection.post(connection.auth_path.chomp('/')+'/tokens', auth_data, {'Content-Type' => 'application/json'})
    end

    def set_connection_attributes(uri, service)
      #grab version to check next time round for multi-version deployments
      @version = get_version_from_response(service)
      connection.service_host = uri.host
      connection.service_path = set_service_path(uri)
      connection.service_port = uri.port
      connection.service_scheme = uri.scheme
      connection.authok = true
    end

    def set_service_path(uri)
      if uri.path.empty? && !connection.default_service_path.nil?
        connection.default_service_path
      else
        uri.path
      end
    end

    def auth_data
      case connection.auth_method
        when 'password'
          JSON.generate({'auth' => {'passwordCredentials' => {'username' => connection.authuser, 'password' => connection.authkey}, connection.authtenant[:type] => connection.authtenant[:value]}})
        when 'rax-kskey'
          JSON.generate({'auth' => {'RAX-KSKEY:apiKeyCredentials' => {'username' => connection.authuser, 'apiKey' => connection.authkey}}})
        when 'key'
          JSON.generate({'auth' => {'apiAccessKeyCredentials' => {'accessKey' => connection.authuser, 'secretKey' => connection.authkey}, connection.authtenant[:type] => connection.authtenant[:value]}})
        else
          raise Exception::InvalidArgument, "Unrecognized auth method #{connection.auth_method}"
      end
    end

    def get_version_from_response(service)
      service['endpoints'].first['versionId'] || parse_version_from_endpoint(service['endpoints'].first['publicURL'])
    end

    #IN  --> https://az-2.region-a.geo-1.compute.hpcloudsvc.com/v1.1/46871569847393
    #OUT --> "1.1"
    def parse_version_from_endpoint(endpoint)
      endpoint.match(/\/v(\d).(\d)/).to_s.sub("/v", '')
    end

  end


  class AuthV10 < Auth

    attr_reader :connection

    def initialize(connection)
      @connection = connection
      set_identity_data
    end

    def set_identity_data
      hdrhash = {'X-Auth-User' => connection.authuser, 'X-Auth-Key' => connection.authkey}
      response = start_server_connection.get(connection.auth_path, hdrhash)

      if (response.code =~ /^20./)
        connection.authtoken = response['x-auth-token']
        case connection.service_type
          when 'compute'
            uri = URI.parse(response['x-server-management-url'])
          when 'object-store'
            uri = URI.parse(response['x-storage-url'])
        end
        raise OpenStack::Exception::Authentication, "Unexpected Response from  #{connection.auth_host} - couldn't get service URLs: \"x-server-management-url\" is: #{response['x-server-management-url']} and \"x-storage-url\" is: #{response['x-storage-url']}" if (uri.host.nil? || uri.host=='')
        connection.service_host = uri.host
        connection.service_path = uri.path
        connection.service_port = uri.port
        connection.service_scheme = uri.scheme
        connection.authok = true
      else
        connection.authok = false
        raise OpenStack::Exception::Authentication, "Authentication failed with response code #{response.code}"
      end
    ensure
      @server.finish if @server.respond_to?(:started?) && @server.started?
    end

  end
end

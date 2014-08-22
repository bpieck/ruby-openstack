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


  private
  class AuthV20
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
      raise OpenStack::Exception::Connection, "Unable to connect to  #{server}"
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


  class AuthV10

    def initialize(connection)

      tries = connection.retries
      time = 3

      hdrhash = {'X-Auth-User' => connection.authuser, 'X-Auth-Key' => connection.authkey}
      begin
        server = Net::HTTP::Proxy(connection.proxy_host, connection.proxy_port).new(connection.auth_host, connection.auth_port)
        if connection.auth_scheme == 'https'
          server.use_ssl = true
          server.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        server.start
      rescue
        puts "Can't connect to the server: #{tries} tries  to reconnect" if connection.is_debug
        sleep time += 1
        retry unless (tries -= 1) <= 0
        raise OpenStack::Exception::Connection, "Unable to connect to #{server}"
      end

      response = server.get(connection.auth_path, hdrhash)

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
      server.finish
    end

  end


#============================
# OpenStack::Exception
#============================

  class Exception

    class ComputeError < StandardError

      attr_reader :response_body
      attr_reader :response_code

      def initialize(message, code, response_body)
        @response_code=code
        @response_body=response_body
        super(message)
      end

    end

    class ComputeFault < ComputeError # :nodoc:
    end
    class ServiceUnavailable < ComputeError # :nodoc:
    end
    class Unauthorized < ComputeError # :nodoc:
    end
    class BadRequest < ComputeError # :nodoc:
    end
    class OverLimit < ComputeError # :nodoc:
    end
    class BadMediaType < ComputeError # :nodoc:
    end
    class BadMethod < ComputeError # :nodoc:
    end
    class ItemNotFound < ComputeError # :nodoc:
    end
    class BuildInProgress < ComputeError # :nodoc:
    end
    class ServerCapacityUnavailable < ComputeError # :nodoc:
    end
    class BackupOrResizeInProgress < ComputeError # :nodoc:
    end
    class ResizeNotAllowed < ComputeError # :nodoc:
    end
    class NotImplemented < ComputeError # :nodoc:
    end
    class Other < ComputeError # :nodoc:
    end
    class ResourceStateConflict < ComputeError # :nodoc:
    end
    class QuantumError < ComputeError # :nodoc:
    end

    # Plus some others that we define here

    class ExpiredAuthToken < StandardError # :nodoc:
    end
    class MissingArgument < StandardError # :nodoc:
    end
    class InvalidArgument < StandardError # :nodoc:
    end
    class TooManyPersonalityItems < StandardError # :nodoc:
    end
    class PersonalityFilePathTooLong < StandardError # :nodoc:
    end
    class PersonalityFileTooLarge < StandardError # :nodoc:
    end
    class Authentication < StandardError # :nodoc:
    end
    class Connection < StandardError # :nodoc:
    end

    # In the event of a non-200 HTTP status code, this method takes the HTTP response, parses
    # the JSON from the body to get more information about the exception, then raises the
    # proper error.  Note that all exceptions are scoped in the OpenStack::Compute::Exception namespace.
    def self.raise_exception(response)
      return if response.code =~ /^20.$/
      begin
        fault = nil
        info = nil
        if response.body.nil? && response.code == '404' #HEAD ops no body returned
          exception_class = self.const_get('ItemNotFound')
          raise exception_class.new('The resource could not be found', '404', '')
        else
          JSON.parse(response.body).each_pair do |key, val|
            fault=key
            info=val
          end
          exception_class = self.const_get(fault[0, 1].capitalize+fault[1, fault.length])
          raise exception_class.new((info['message'] || info), response.code, response.body)
        end
      rescue JSON::ParserError => parse_error
        deal_with_faulty_error(response, parse_error)
      rescue NameError
        raise OpenStack::Exception::Other.new("The server returned status #{response.code}", response.code, response.body)
      end
    end

    private

    #e.g. os.delete("non-existant") ==> response.body is:
    # "404 Not Found\n\nThe resource could not be found.\n\n   "
    # which doesn't parse. Deal with such cases here if possible (JSON::ParserError)
    def self.deal_with_faulty_error(response, parse_error)
      case response.code
        when '404'
          klass = self.const_get('ItemNotFound')
          msg = 'The resource could not be found'
        when '409'
          klass = self.const_get('ResourceStateConflict')
          msg = 'There was a conflict with the state of the resource'
        else
          klass = self.const_get('Other')
          msg = "Oops - not sure what happened: #{parse_error}"
      end
      raise klass.new(msg, response.code.to_s, response.body)
    end
  end

end

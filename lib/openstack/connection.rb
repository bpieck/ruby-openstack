module OpenStack

  class Connection

    attr_reader :authuser
    attr_reader :authtenant
    attr_reader :authkey
    attr_reader :auth_method
    attr_accessor :authtoken
    attr_accessor :authok
    attr_accessor :service_host
    attr_accessor :service_path
    attr_accessor :service_port
    attr_accessor :service_scheme
    attr_accessor :service_url_type
    attr_accessor :quantum_version
    attr_reader :retries
    attr_reader :auth_host
    attr_reader :auth_port
    attr_reader :auth_scheme
    attr_reader :auth_path
    attr_reader :default_service_path
    attr_reader :service_name
    attr_reader :service_type
    attr_reader :proxy_host
    attr_reader :proxy_port
    attr_reader :ca_cert
    attr_reader :ssl_version
    attr_reader :region
    attr_reader :regions_list #e.g. os.connection.regions_list == {"region-a.geo-1" => [ {:service=>"object-store", :versionId=>"1.0"}, {:service=>"identity", :versionId=>"2.0"}], "region-b.geo-1"=>[{:service=>"identity", :versionId=>"2.0"}] }

    attr_reader :http
    attr_reader :is_debug

    # Creates and returns a new Connection object, depending on the service_type
    # passed in the options:
    #
    # e.g:
    # os = OpenStack::Connection.create({:username => "herp@derp.com", :api_key=>"password",
    #               :auth_url => "https://region-a.geo-1.identity.cloudsvc.com:35357/v2.0/",
    #               :authtenant=>"herp@derp.com-default-tenant", :service_type=>"object-store")
    #
    # Will return an OpenStack::Swift::Connection object.
    #
    #   options hash:
    #
    #   :auth_method - Type of authentication - 'password', 'key', 'rax-kskey' - defaults to 'password'
    #   :username - Your OpenStack username or public key, depending on auth_method. *required*
    #   :authtenant_name OR :authtenant_id - Your OpenStack tenant name or id *required*. Defaults to username.
    #     passing :authtenant will default to using that parameter as tenant name.
    #   :api_key - Your OpenStack API key *required* (either private key or password, depending on auth_method)
    #   :auth_url - Configurable auth_url endpoint.
    #   :service_name - (Optional for v2.0 auth only). The optional name of the compute service to use.
    #   :service_type - (Optional for v2.0 auth only). Defaults to "compute"
    #   :region - (Optional for v2.0 auth only). The specific service region to use. Defaults to first returned region.
    #   :retry_auth - Whether to retry if your auth token expires (defaults to true)
    #   :proxy_host - If you need to connect through a proxy, supply the hostname here
    #   :proxy_port - If you need to connect through a proxy, supply the port here
    #   :ca_cert - path to a CA chain in PEM format
    #   :ssl_version - explicitly set an version (:SSLv3 etc, see  OpenSSL::SSL::SSLContext::METHODS)
    #
    # The options hash is used to create a new OpenStack::Connection object
    # (private constructor) and this is passed to the constructor of OpenStack::Compute::Connection
    # or OpenStack::Swift::Connection (depending on :service_type) where authentication is done using
    # OpenStack::Authentication.
    #
    def self.create(options = {retry_auth: true})
      #call private constructor and grab instance vars
      connection = new(options)
      case connection.service_type
        when 'identity'
          OpenStack::Identity::Connection.new(connection)
        when 'compute'
          OpenStack::Compute::Connection.new(connection)
        when 'object-store'
          OpenStack::Swift::Connection.new(connection)
        when 'volume'
          OpenStack::Volume::Connection.new(connection)
        when 'image'
          OpenStack::Image::Connection.new(connection)
        when 'network'
          OpenStack::Network::Connection.new(connection)
        when 'metering'
          OpenStack::Metering::Connection.new(connection)
        else
          raise Exception::InvalidArgument, "Invalid :service_type parameter: #{@service_type}"
      end
    end

    private_class_method :new

    def initialize(options = {retry_auth: true})
      @retries = options[:retries] || 3
      @authuser = options[:username] || (raise Exception::MissingArgument, 'Must supply a :username')
      @authkey = options[:api_key] || (raise Exception::MissingArgument, 'Must supply an :api_key')
      @auth_url = options[:auth_url] || (raise Exception::MissingArgument, 'Must supply an :auth_url')
      @authtenant = (options[:authtenant_id]) ? {type: 'tenantId', value: options[:authtenant_id]} : {type: 'tenantName', value: (options[:authtenant_name] || options[:authtenant] || @authuser)}
      @auth_method = options[:auth_method] || 'password'
      @service_name = options[:service_name] || nil
      @service_type = options[:service_type] || 'compute'
      @default_service_path = options[:default_service_path] # set this option, if you want to overwrite empty paths from keystone
      @service_url_type = options[:service_url_type]
      @region = options[:region] || @region = nil
      @regions_list = {} # this is populated during authentication - from the returned service catalogue
      @is_debug = options[:is_debug]
      auth_uri=nil
      begin
        auth_uri=URI.parse(@auth_url)
      rescue Exception => e
        raise Exception::InvalidArgument, "Invalid :auth_url parameter: #{e.message}"
      end
      raise Exception::InvalidArgument, 'Invalid :auth_url parameter.' if auth_uri.nil? or auth_uri.host.nil?
      @auth_host = auth_uri.host
      @auth_port = auth_uri.port
      @auth_scheme = auth_uri.scheme
      @auth_path = auth_uri.path
      @retry_auth = options[:retry_auth]
      @proxy_host = options[:proxy_host]
      @proxy_port = options[:proxy_port]
      @ca_cert = options[:ca_cert]
      @ssl_version = options[:ssl_version]
      @authok = false
      @http = {}
      @quantum_version = '/v2.0' if @service_type == 'network'
    end

    #specialised from of csreq for PUT object... uses body_stream if possible
    def put_object(server, path, port, scheme, headers = {}, data = nil, attempts = 0) # :nodoc:

      tries = @retries
      time = 3

      if data.respond_to? :read
        headers['Transfer-Encoding'] = 'chunked'
        hdrhash = headerprep(headers)
        request = Net::HTTP::Put.new(path, hdrhash)
        chunked = OpenStack::Swift::ChunkedConnectionWrapper.new(data, 65535)
        request.body_stream = chunked
      else
        headers['Content-Length'] = (data.respond_to?(:lstat)) ? data.lstat.size.to_s : ((data.respond_to?(:size)) ? data.size.to_s : '0')
        hdrhash = headerprep(headers)
        request = Net::HTTP::Put.new(path, hdrhash)
        request.body = data
      end
      start_http(server, path, port, scheme, hdrhash)
      response = @http[server].request(request)
      if @is_debug
        puts "REQUEST: #{method} => #{path}"
        puts data if data
        puts "RESPONSE: #{response.body}"
        puts '----------------------------------------'
      end
      raise OpenStack::Exception::ExpiredAuthToken if response.code == '401'
      response
    rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError
      # Server closed the connection, retry
      puts "Can't connect to the server: #{tries} tries to reconnect" if @is_debug
      sleep time += 1
      @http[server].finish if @http[server].started?
      retry unless (tries -= 1) <= 0
      raise OpenStack::Exception::Connection, "Unable to connect to #{server} after #{@retries} retries"

    rescue OpenStack::Exception::ExpiredAuthToken
      raise OpenStack::Exception::Connection, 'Authentication token expired and you have requested not to retry' if @retry_auth == false
      OpenStack::Authentication.init(self)
      retry
    end


    # This method actually makes the HTTP REST calls out to the server
    def csreq(method, server, path, port, scheme, headers = {}, data = nil, attempts = 0, &block) # :nodoc:

      tries = @retries
      time = 3

      hdrhash = headerprep(headers)
      start_http(server, path, port, scheme, hdrhash)
      request = Net::HTTP.const_get(method.to_s.capitalize).new(path, hdrhash)
      request.body = data
      if block_given?
        response = @http[server].request(request) do |res|
          res.read_body do |b|
            yield b
          end
        end
      else
        response = @http[server].request(request)
      end
      if @is_debug
        puts "REQUEST: #{method} => #{path}"
        puts data if data
        puts "RESPONSE: #{response.body}"
        puts '----------------------------------------'
      end
      raise OpenStack::Exception::ExpiredAuthToken if response.code == '401'
      response
    rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError
      # Server closed the connection, retry
      puts "Can't connect to the server: #{tries} tries to reconnect" if @is_debug
      sleep time += 1
      @http[server].finish if @http[server].started?
      retry unless (tries -= 1) <= 0
      raise OpenStack::Exception::Connection, "Unable to connect to #{server} after #{@retries} retries"
    rescue OpenStack::Exception::ExpiredAuthToken
      raise OpenStack::Exception::Connection, 'Authentication token expired and you have requested not to retry' if @retry_auth == false
      OpenStack::Authentication.init(self)
      retry
    end

    # This is a much more sane way to make a http request to the api.
    # Example: res = conn.req('GET', "/servers/#{id}")
    def req(method, path, options = {})
      server = options[:server] || @service_host
      port = options[:port] || @service_port
      scheme = options[:scheme] || @service_scheme
      headers = options[:headers] || {'content-type' => 'application/json'}
      data = options[:data]
      attempts = options[:attempts] || 0
      path = @service_path + @quantum_version.to_s + path
      res = csreq(method, server, path, port, scheme, headers, data, attempts)
      res.code.match(/^20.$/) ? (return res) : OpenStack::Exception.raise_exception(res)
    end

    private

    # Sets up standard HTTP headers
    def headerprep(headers = {}) # :nodoc:
      default_headers = {}
      default_headers['X-Auth-Token'] = @authtoken if authok
      default_headers['X-Storage-Token'] = @authtoken if authok
      default_headers['Connection'] = 'Keep-Alive'
      default_headers['User-Agent'] = "OpenStack Ruby API #{OpenStack::VERSION}"
      default_headers['Accept'] = 'application/json'
      default_headers.merge(headers)
    end

    # Starts (or restarts) the HTTP connection
    def start_http(server, path, port, scheme, headers) # :nodoc:

      tries = @retries
      time = 3

      if (@http[server].nil?)
        begin
          @http[server] = Net::HTTP::Proxy(@proxy_host, @proxy_port).new(server, port)
          if scheme == 'https'
            @http[server].use_ssl = true
            @http[server].verify_mode = OpenSSL::SSL::VERIFY_NONE

            # use the ca_cert if were given one, and make sure we verify!
            if ! @ca_cert.nil?
              @http[server].ca_file = @ca_cert
              @http[server].verify_mode = OpenSSL::SSL::VERIFY_PEER
            end

            # explicitly set the SSL version to use
            @http[server].ssl_version= @ssl_version if ! @ssl_version.nil?
          end
          @http[server].start
        rescue
          puts "Can't connect to the server: #{tries} tries to reconnect" if @is_debug
          sleep time += 1
          retry unless (tries -= 1) <= 0
          raise OpenStack::Exception::Connection, "Unable to connect to #{server}"
        end
      end
    end
  end

end


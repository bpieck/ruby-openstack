module OpenStack
  module Identity

    class Connection

      attr_accessor :connection
      attr_accessor :extensions

      def initialize(connection)
        @extensions = nil
        @connection = connection
        @connection.service_url_type = :admin if @connection.service_url_type.nil?
        OpenStack::Authentication.init(@connection)
      end

      def tenants
        response = @connection.csreq('GET', @connection.service_host, "#{@connection.service_path}/tenants", @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        tenant_list = JSON.parse(response.body)
        OpenStack.symbolize_keys(tenant_list['tenants'])
      end

      def tenant(tenant_id)
        raise OpenStack::Exception::InvalidArgument.new("tenant_id #{tenant_id} looks suspicious") unless tenant_id && tenant_id =~ /\A\w+\Z/
        response = @connection.csreq('GET', @connection.service_host, "#{@connection.service_path}/tenants/#{tenant_id}", @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        tenant_list = JSON.parse(response.body)
        OpenStack.symbolize_keys(tenant_list['tenant'])
      end

      def endpoints
        response = @connection.csreq('GET', @connection.service_host, "#{@connection.service_path}/endpoints", @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        endpoint_list = JSON.parse(response.body)
        OpenStack.symbolize_keys(endpoint_list['endpoints'])
      end

    end
  end
end
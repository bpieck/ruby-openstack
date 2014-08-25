module OpenStack
  module Metering

    class Connection

      attr_accessor :connection
      attr_accessor :extensions

      def initialize(connection)
        @extensions = nil
        @connection = connection
        OpenStack::Authentication.init(@connection)
      end

      # Returns true if the authentication was successful and returns false otherwise.
      #
      #   cs.authok?
      #   => true
      def authok?
        @connection.authok
      end


      # Telemetry request for all meters
      # set query with os.meters(q: '<query>')
      # http://developer.openstack.org/api-ref-telemetry-v2.html

      def meters(options = {})
        path = OpenStack.get_ceilometer_query(options, [:q], "#{@connection.service_path}/meters")
        response = @connection.csreq('GET', @connection.service_host, path, @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      end

      # Telemetry request for meter bandwidth
      # set query and limit with for example: os.meters(q: '<query>', limit: 20)
      # http://developer.openstack.org/api-ref-telemetry-v2.html

      def bandwidth(options = {})
        path = OpenStack.get_query_params(options, [:q, :limit, :project_id, :resource_id, :message_id], "#{@connection.service_path}/meters/bandwidth")
        response = @connection.csreq('GET', @connection.service_host, path, @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        bandwidth_list = JSON.parse(response.body)
        OpenStack.symbolize_keys bandwidth_list
      end

    end

  end
end

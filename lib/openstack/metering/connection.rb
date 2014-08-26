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
        path = OpenStack.get_ceilometer_query(options, [:project_id, :resource_id, :message_id, :start, :end], :limit, "#{@connection.service_path}/meters")
        response = @connection.csreq('GET', @connection.service_host, path, @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      end

      # Telemetry request for meter bandwidth
      # set query and limit with for example: os.accumulated_bandwidth(resource_id: 'some-id', limit: 20)
      # http://developer.openstack.org/api-ref-telemetry-v2.html

      def accumulated_bandwidth(options = {})
        path = OpenStack.get_ceilometer_query(options, [:project_id, :resource_id, :start, :end], :limit, "#{@connection.service_path}/meters/bandwidth/statistics")
        response = @connection.csreq('GET', @connection.service_host, path, @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        bandwidth_list = JSON.parse(response.body)
        OpenStack.symbolize_keys bandwidth_list
      end

      # Telemetry sample-list request for meter bandwidth
      # set query and limit with for example: os.bandwidth(resource_id: 'some-id', limit: 20)
      # http://developer.openstack.org/api-ref-telemetry-v2.html

      def bandwidth(options={})
        sample_list 'bandwidth', options
      end

      # Telemetry sample-list request for variable meter
      # set query and limit with for example: os.sample_list('<meter>', resource_id: 'some-id', limit: 20)
      # http://developer.openstack.org/api-ref-telemetry-v2.html

      def sample_list(meter, options = {})
        path = OpenStack.get_ceilometer_query(options, [:project_id, :resource_id, :start, :end], :limit, "#{@connection.service_path}/meters/#{meter}")
        response = @connection.csreq('GET', @connection.service_host, path, @connection.service_port, @connection.service_scheme)
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        bandwidth_list = JSON.parse(response.body)
        OpenStack.symbolize_keys bandwidth_list
      end

    end

  end
end

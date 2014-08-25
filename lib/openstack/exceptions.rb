#============================
# OpenStack::Exception
#============================
module OpenStack
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
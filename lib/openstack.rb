#!/usr/bin/env ruby
#
# == Ruby OpenStack API
#
# See COPYING for license information.
# ----
#
# === Documentation & Examples
# To begin reviewing the available methods and examples, view the README.rdoc file
#
# Example:
# os = OpenStack::Connection.create({:username => "herp@derp.com", :api_key=>"password",
#               :auth_url => "https://region-a.geo-1.identity.cloudsvc.com:35357/v2.0/",
#               :authtenant=>"herp@derp.com-default-tenant", :service_type=>"object-store")
#
# will return a handle to the object-storage service swift. Alternatively, passing
# :service_type=>"compute" will return a handle to the compute service nova.

module OpenStack

  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'rubygems'
  require 'json'
  require 'date'

  unless "".respond_to? :each_char
    require "jcode"
    $KCODE = 'u'
  end

  $:.unshift(File.dirname(__FILE__))
  require 'openstack/authentication'
  require 'openstack/connection'
  require 'openstack/connector'
  require 'openstack/exceptions'
  require 'openstack/compute/connection'
  require 'openstack/compute/server'
  require 'openstack/compute/image'
  require 'openstack/compute/flavor'
  require 'openstack/compute/address'
  require 'openstack/compute/personalities'
  require 'openstack/identity/connection'
  require 'openstack/image/connection'
  require 'openstack/metering/connection'
  require 'openstack/network/connection'
  require 'openstack/network/network'
  require 'openstack/network/subnet'
  require 'openstack/network/router'
  require 'openstack/network/port'
  require 'openstack/swift/connection'
  require 'openstack/swift/container'
  require 'openstack/swift/storage_object'
  require 'openstack/volume/connection'
  require 'openstack/volume/volume'
  require 'openstack/volume/snapshot'
  require 'openstack/version'
  # Constants that set limits on server creation
  MAX_PERSONALITY_ITEMS = 5
  MAX_PERSONALITY_FILE_SIZE = 10240
  MAX_SERVER_PATH_LENGTH = 255

  # Helper method to recursively symbolize hash keys.
  def self.symbolize_keys(obj)
    case obj
      when Array
        obj.inject([]) { |res, val|
          res << case val
                   when Hash, Array
                     symbolize_keys(val)
                   else
                     val
                 end
          res
        }
      when Hash
        obj.inject({}) { |res, (key, val)|
          nkey = case key
                   when String
                     key.to_sym
                   else
                     key
                 end
          nval = case val
                   when Hash, Array
                     symbolize_keys(val)
                   else
                     val
                 end
          res[nkey] = nval
          res
        }
      else
        obj
    end
  end

  def self.paginate(options = {})
    path_args = []
    path_args.push(URI.encode("limit=#{options[:limit]}")) if options[:limit]
    path_args.push(URI.encode("offset=#{options[:offset]}")) if options[:offset]
    path_args.join("&")
  end

  # e.g. keys = [:limit, :marker]
  # params = {:limit=>2, :marker="marios", :prefix=>"/"}
  # you want url = /container_name?limit=2&marker=marios
  def self.get_query_params(params, keys, url="")
    keys = [keys] unless keys.is_a?(Array)
    set_keys = filter_keys(params, keys)
    return url if set_keys.empty?
    url = "#{url}?#{set_keys[0]}=#{value_for params[set_keys[0]]}"
    set_keys.slice!(0)
    set_keys.each do |k|
      url = "#{url}&#{k}=#{value_for params[set_keys[0]]}"
    end
    url
  end

  def self.get_metering_query(params, metering_keys, query_keys, url="")
    metering_keys = [metering_keys] unless metering_keys.is_a?(Array)
    keys = filter_keys(params, metering_keys)
    if keys.empty?
      get_query_params(params, query_keys, url)
    else
      other_params = get_query_params(params, query_keys)
      if other_params.empty?
        "#{url}?#{metering_fields(keys)}&#{metering_operations(keys)}&#{metering_types(keys)}&#{metering_values(keys, params)}"
      else
        "#{url}#{other_params}&#{metering_fields(keys)}&#{metering_operations(keys)}&#{metering_types(keys)}&#{metering_values(keys, params)}"
      end
    end
  end

  def self.metering_values(keys, params)
    keys.map { |key| "q.value=#{value_for params[key]}" }.join('&')
  end

  def self.metering_fields(keys)
    keys.map { |key| "q.field=#{metering_field_for key}" }.join('&')
  end

  def self.metering_types(keys)
    keys.map { |key| "q.type=" }.join('&')
  end

  def self.metering_operations(keys)
    keys.map { |key| "q.op=#{metering_operation_for key}" }.join('&')
  end

  def self.value_for(value)
    case value
      when Time
        value.strftime('%Y-%m-%dT%H:%M:%S.%6N')
      else
        value
    end
  end

  def self.metering_operation_for(key)
    case key.to_sym
      when :resource_id, :project_id
        'eq'
      when :start
        'ge'
      when :end
        'le'
    end
  end

  def self.metering_field_for(key)
    case key.to_sym
      when :start, :end
        'timestamp'
      else
        key
    end
  end

  def self.filter_keys(params, keys)
    params.inject([]) { |res, (k, v)| res << k if keys.include?(k) and not v.nil?; res }
  end

end

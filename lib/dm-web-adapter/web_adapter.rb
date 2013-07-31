module DataMapper
  module Adapters
    class WebAdapter < DataMapper::Adapters::AbstractAdapter
      include DataMapper::Adapters::Web::Parser
      include DataMapper::Adapters::Web::UrlBuilder
      
      def initialize(name, options)
        super
        @options = options
        @format = :html
        @mappings = options.fetch(:mappings)
        @agent = Mechanize.new
        @agent.log = DataMapper.logger
        @agent.user_agent_alias = 'Mac Safari'
        @agent.redirect_ok = false
      end
      
      # Persists one or many new resources
      #
      # @example
      #   adapter.create(collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Enumerable<Resource>] resources
      #   The list of resources (model instances) to create
      #
      # @return [Integer]
      #   The number of records that were actually saved into the data-store
      #
      # @api semipublic  
      def create(resources)
        created = 0
        resources.each do |resource|
          model = resource.model
          storage_name = model.storage_name(resource.repository)
          DataMapper.logger.debug("About to create #{model} backed by #{storage_name} using #{resource.attributes}")

          begin
            create_url = build_create_url(storage_name.to_sym)
            page = @agent.get(create_url) 
            form_id = build_form_id(storage_name.to_sym)
            create_form = page.form_with(:id => form_id)
            DataMapper.logger.debug("Create form is #{create_form.inspect}")
            resource.attributes(key_on=:field).reject{|p,v| v.nil? }.each do |property, value|
              DataMapper.logger.debug("Setting #{property.inspect} to #{value.inspect}")
              field = create_form.field_with(:name => build_property_name(storage_name, property))
              DataMapper.logger.debug("Pulled field #{field.inspect} using #{build_property_name(storage_name, property)}")
              field.value = value
            end
            response = @agent.submit(create_form)
            DataMapper.logger.debug("Result of actual create call is #{response.code}")
            if response.code.to_i == 302
              redirect_location = response.header['location']
              DataMapper.logger.debug("Redirect location is #{redirect_location}")
              id = redirect_location.split('/').last
              DataMapper.logger.debug("Newly created instance id is #{id}")
              unless id.nil?
                initialize_serial(resource, id)
                created += 1
              end
            end
          rescue => e
            trace = e.backtrace.join("\n")
            DataMapper.logger.error("Failed to create resource: #{e.message}")  
            DataMapper.logger.error(trace)  
          end
        end
        created
      end
      
      # Reads one or many resources from a datastore
      #
      # @example
      #   adapter.read(query)  # => [ { 'name' => 'Dan Kubb' } ]
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Query] query
      #   the query to match resources in the datastore
      #
      # @return [Enumerable<Hash>]
      #   an array of hashes to become resources
      #
      # @api semipublic
      def read(query)
        DataMapper.logger.debug("Read #{query.inspect} and its model is #{query.model.inspect}")
        model = query.model
        query_url = build_query_url(query)
        begin
          page = @agent.get(query_url) 
          DataMapper.logger.debug("Page was #{page.inspect}")
          return parse_collection(page, model)
        rescue => e
          trace = e.backtrace.join("\n")
          DataMapper.logger.error("Failed to query: #{e.message}")  
          DataMapper.logger.error(trace)
        end
      end
      
    end
  end
end
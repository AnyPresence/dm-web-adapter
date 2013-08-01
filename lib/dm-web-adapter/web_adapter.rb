module DataMapper
  module Adapters
    class WebAdapter < DataMapper::Adapters::AbstractAdapter
      include DataMapper::Adapters::Web::Parser
      include DataMapper::Adapters::Web::UrlBuilder
      include DataMapper::Adapters::Web::FormHelper
      
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
          serial = model.serial
          storage_name = model.storage_name(resource.repository)
          DataMapper.logger.debug("About to create #{model} backed by #{storage_name} using #{resource.attributes}")

          begin
            create_url = build_create_url(storage_name)
            page = @agent.get(create_url) 
            form_id = build_form_id(storage_name.to_sym, :create_form_id)
            the_form = page.form_with(:id => form_id)
            the_properties = resource.attributes(key_on=:field).reject{|p,v| v.nil? }
            create_form = fill_form(the_form, the_properties, storage_name)
            DataMapper.logger.debug("Create form is #{create_form.inspect}")
            response = @agent.submit(create_form)
            DataMapper.logger.debug("Result of actual create call is #{response.code}")
            if response.code.to_i == 302
              redirect_location = response.header['location']
              DataMapper.logger.debug("Redirect location is #{redirect_location}")
              id = redirect_location.split('/').last.to_i #TODO: proper cast
              DataMapper.logger.debug("Newly created instance id is #{id}")
              unless id.nil?
                serial.set(resource,id)
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
        records = []
        begin
          page = @agent.get(query_url) 
          DataMapper.logger.debug("Page was #{page.inspect}")
          records = parse_collection(page, model, query.fields)
          DataMapper.logger.debug("Records are #{records.inspect}")
        rescue => e
          trace = e.backtrace.join("\n")
          DataMapper.logger.error("Failed to query: #{e.message}")  
          DataMapper.logger.error(trace)
        end
        return records
      end
      
      # Updates one or many existing resources
      #
      # @example
      #   adapter.update(attributes, collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Hash(Property => Object)] attributes
      #   hash of attribute values to set, keyed by Property
      # @param [Collection] collection
      #   collection of records to be updated
      #
      # @return [Integer]
      #   the number of records updated
      #
      # @api semipublic
      def update(attributes, collection)
        DataMapper.logger.debug("Update called with:\nAttributes #{attributes.inspect} \nCollection: #{collection.inspect}")
        updated = 0
        the_properties = {}
        attributes.each{|property, value| the_properties[property.field] = value}
        collection.each do |resource|
          model = resource.model
          storage_name = model.storage_name(resource.repository)
          id = model.serial.get(resource)
          DataMapper.logger.debug("Building edit URL with #{model} and #{id}")
          edit_url = build_edit_url(storage_name, id)
          begin
            page = @agent.get(edit_url) 
            form_id = build_form_id(storage_name, :update_form_id, id)
            DataMapper.logger.debug("Form id is #{form_id}")
            the_form = page.form_with(:id => form_id)
            update_form = fill_form(the_form, the_properties, storage_name)
            DataMapper.logger.debug("Update form is #{update_form.inspect}")
            response = @agent.submit(update_form)
            DataMapper.logger.debug("Result of actual update call is #{response.code}")
            if response.code.to_i == 302
              updated += 1
            end
          rescue => e
            DataMapper.logger.error("Failure while updating #{e.inspect}")
          end
        end

        updated
      end
    end
  end
end
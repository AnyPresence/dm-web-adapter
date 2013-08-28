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
        @agent.user_agent_alias = 'Mac Safari'
        @agent.redirect_ok = false
        initialize_logger
      end
      
      def initialize_logger
        level = 'debug' # 'error'

        if @options[:logging_level] && %w[ off fatal error warn info debug ].include?(@options[:logging_level].downcase)
          level = @options[:logging_level].downcase
        end
        DataMapper::Logger.new($stdout,level)
        @log = DataMapper.logger
        if level == 'debug'
          @log.debug("Adding agent debugging proxy")
          @agent.log = @log
        end
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
          @log.debug("About to create #{model} backed by #{storage_name} using #{resource.attributes}")

          begin
            create_url = build_create_url(storage_name)
            page = @agent.get(create_url) 
            form_id = build_form_id(storage_name.to_sym, :create_form_id)
            the_form = page.form_with(:id => form_id)
            the_properties = resource.attributes(key_on=:field).reject{|p,v| v.nil? }
            create_form = fill_form(the_form, the_properties, storage_name)
            @log.debug("Create form is #{create_form.inspect}")
            response = @agent.submit(create_form)
            @log.debug("Result of actual create call is #{response.code}")
            if response.code.to_i == 302
              redirect_location = response.header['location']
              @log.debug("Redirect location is #{redirect_location}")
              id = redirect_location.split('/').last.to_i #TODO: proper cast
              @log.debug("Newly created instance id is #{id}")
              unless id.nil?
                serial.set(resource,id)
                created += 1
              end
            end
          rescue => e
            trace = e.backtrace.join("\n")
            @log.error("Failed to create resource: #{e.message}")  
            @log.error(trace)  
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
        @log.debug("Read #{query.inspect} and its model is #{query.model.inspect}")
        model = query.model
        query_url = build_query_url(query)
        records = []
        begin
          page = @agent.get(query_url) 
          @log.debug("Page was #{page.inspect}")
          records = parse_collection(page, model, query.fields)
          @log.debug("Records are #{records.inspect}")
        rescue => e
          trace = e.backtrace.join("\n")
          @log.error("Failed to query: #{e.message}")  
          @log.error(trace)
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
        @log.debug("Update called with:\nAttributes #{attributes.inspect} \nCollection: #{collection.inspect}")
        updated = 0
        the_properties = {}
        attributes.each{|property, value| the_properties[property.field] = value}
        collection.each do |resource|
          model = resource.model
          storage_name = model.storage_name(resource.repository)
          id = model.serial.get(resource)
          @log.debug("Building edit URL with #{model} and #{id}")
          edit_url = build_edit_url(storage_name, id)
          begin
            page = @agent.get(edit_url) 
            form_id = build_form_id(storage_name, :update_form_id, id)
            @log.debug("Form id is #{form_id}")
            the_form = page.form_with(:id => form_id)
            update_form = fill_form(the_form, the_properties, storage_name)
            @log.debug("Update form is #{update_form.inspect}")
            response = @agent.submit(update_form)
            @log.debug("Result of actual update call is #{response.code}")
            if response.code.to_i == 302
              updated += 1
            end
          rescue => e
            @log.error("Failure while updating #{e.inspect}")
          end
        end

        updated
      end
      
      # Deletes one or many existing resources
      #
      # @example
      #   adapter.delete(collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Collection] collection
      #   collection of records to be deleted
      #
      # @return [Integer]
      #   the number of records deleted
      #
      # @api semipublic
      def delete(collection)
        @log.debug("Delete called with: #{collection.inspect}")
        deleted = 0
        model = collection.first.model
        storage_name = model.storage_name
        all_url = build_all_url(storage_name)
        page = @agent.get(all_url) 
        @log.debug("Page was #{page.inspect}")
        records = parse_collection(page, model)
         
        collection.each do |resource|
          begin
            id = model.serial.get(resource)
            delete_link = build_delete_link(storage_name, id)
            @log.debug("Delete link is #{delete_link}")
            #actual_delete_link = page.link_with(:href => delete_link, :text => 'Destroy')
            # No can do Javascript prompts, so...
            response = @agent.delete(delete_link)
            @log.debug("Result of actual delete call is #{response.code}")
            if response.code.to_i == 302
              deleted += 1
            else
              @log.error("Failure while deleting #{response.inspect}")
            end
          rescue => e
            @log.error("Failure while deleting #{e.inspect}")
          end
        end

        deleted
      end
      
    end
  end
end
module DataMapper
  module Adapters
    class WebAdapter < DataMapper::Adapters::AbstractAdapter
      
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
            @agent.follow_meta_refresh = false
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
      
      private
      
      def update_attributes(resource, body)
        DataMapper.logger.debug("update_attributes(#{resource}, #{body})")
        return if DataMapper::Ext.blank?(body)
        fields = {}
        model      = resource.model
        properties = model.properties(key_on=:field)

        properties.each do |prop| 
          fields[prop.field.to_sym] = prop.name.to_sym 
        end

        parse_record(body, model).each do |key, value|
          if property = properties[fields[key.to_sym]]
            property.set!(resource, value)
          end
        end
      end
      
      def parse_record(json, model)
        hash = JSON.parse(json)
        field_to_property = Hash[ properties(model).map { |p| [ p.field, p ] } ]
        record_from_hash(hash, field_to_property)
      end
      
      def record_from_hash(hash, field_to_property)
        record = {}
        hash.each_pair do |field, value|
          next unless property = field_to_property[field]
          record[field] = property.typecast(value)
        end

        record
      end
                        
      def configured_mapping(storage_name)
        DataMapper.logger.debug("@mappings are #{@mappings.inspect} and storage_name is #{storage_name.inspect}")
        @mappings.fetch(storage_name)
      end
      
      def build_create_url(storage_name)
        configured_path = configured_mapping(storage_name).fetch(:create_path)
        path = configured_path.nil? ? "#{storage_name.to_s}.#{@format.to_s}" : configured_path
        url = "#{@options[:scheme]}://#{@options[:host]}:#{@options[:port]}/#{path}"
        DataMapper.logger.debug("Will use #{url} to create")
        url
      end
      
      def build_form_id(storage_name)
        configured_mapping(storage_name).fetch(:create_form_id)
      end
      
      def build_property_name(storage_name, property)
        "#{DataMapper::Inflector.singularize(storage_name.to_s)}[#{property}]"
      end
    end
  end
end
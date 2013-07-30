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
            page = @agent.get build_create_url(storage_name.to_sym)
            create_form = page.form_with :id => build_form_id(storage_name.to_sym)
            DataMapper.logger.debug("Create form is #{create_form.inspect}")
            resource.attributes(key_on=:field).each do |property, value|
              DataMapper.logger.debug("Setting #{property.inspect} to #{value.inspect}")
              create_form.field_with(:name => property).value = value
            end
            response = agent.submit
            DataMapper.logger.debug("Result of actual create call is #{response.inspect}")
            result = update_attributes(resource, response.body)
            created += 1
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
        return if DataMapper::Ext.blank?(body)
        fields = {}
        model      = resource.model
        properties = model.properties(repository_name)

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
    end
  end
end
module ActiveRecord
  module Associations
    class HasManyThroughAssociation < AssociationProxy #:nodoc:
      def initialize(owner, reflection)
        super
        reflection.check_validity!
        @finder_sql = construct_conditions
        construct_sql
      end

      def find(*args)
        options = args.extract_options!

        conditions = "#{@finder_sql}"
        if sanitized_conditions = sanitize_sql(options[:conditions])
          conditions << " AND (#{sanitized_conditions})"
        end
        options[:conditions] = conditions

        if options[:order] && @reflection.options[:order]
          options[:order] = "#{options[:order]}, #{@reflection.options[:order]}"
        elsif @reflection.options[:order]
          options[:order] = @reflection.options[:order]
        end

        options[:select]  = construct_select(options[:select])
        options[:from]  ||= construct_from
        options[:joins]   = construct_joins(options[:joins])
        options[:include] = @reflection.source_reflection.options[:include] if options[:include].nil?

        merge_options_from_reflection!(options)

        # Pass through args exactly as we received them.
        args << options
        @reflection.klass.find(*args)
      end

      def reset
        @target = []
        @loaded = false
      end

      # Adds records to the association. The source record and its associates
      # must have ids in order to create records associating them, so this
      # will raise ActiveRecord::HasManyThroughCantAssociateNewRecords if
      # either is a new record.  Calls create! so you can rescue errors.
      #
      # The :before_add and :after_add callbacks are not yet supported.
      def <<(*records)
        return if records.empty?
        through = @reflection.through_reflection
        raise ActiveRecord::HasManyThroughCantAssociateNewRecords.new(@owner, through) if @owner.new_record?

        klass = through.klass
        klass.transaction do
          flatten_deeper(records).each do |associate|
            raise_on_type_mismatch(associate)
            raise ActiveRecord::HasManyThroughCantAssociateNewRecords.new(@owner, through) unless associate.respond_to?(:new_record?) && !associate.new_record?

            @owner.send(@reflection.through_reflection.name).proxy_target << klass.send(:with_scope, :create => construct_join_attributes(associate)) { klass.create! }
            @target << associate if loaded?
          end
        end

        self
      end

      [:push, :concat].each { |method| alias_method method, :<< }

      # Removes +records+ from this association.  Does not destroy +records+.
      def delete(*records)
        records = flatten_deeper(records)
        records.each { |associate| raise_on_type_mismatch(associate) }

        through = @reflection.through_reflection
        raise ActiveRecord::HasManyThroughCantDissociateNewRecords.new(@owner, through) if @owner.new_record?

        load_target

        klass = through.klass
        klass.transaction do
          flatten_deeper(records).each do |associate|
            raise_on_type_mismatch(associate)
            raise ActiveRecord::HasManyThroughCantDissociateNewRecords.new(@owner, through) unless associate.respond_to?(:new_record?) && !associate.new_record?

            klass.delete_all(construct_join_attributes(associate))
            @target.delete(associate)
          end
        end

        self
      end

      def build(attrs = nil)
        raise ActiveRecord::HasManyThroughCantAssociateNewRecords.new(@owner, @reflection.through_reflection)
      end
      alias_method :new, :build

      def create!(attrs = nil)
        @reflection.klass.transaction do
          self << (object = @reflection.klass.send(:with_scope, :create => attrs) { @reflection.klass.create! })
          object
        end
      end

      # Returns the size of the collection by executing a SELECT COUNT(*) query if the collection hasn't been loaded and
      # calling collection.size if it has. If it's more likely than not that the collection does have a size larger than zero
      # and you need to fetch that collection afterwards, it'll take one less SELECT query if you use length.
      def size
        return @owner.send(:read_attribute, cached_counter_attribute_name) if has_cached_counter?
        return @target.size if loaded?
        return count
      end

      # Calculate sum using SQL, not Enumerable
      def sum(*args)
        if block_given?
          calculate(:sum, *args) { |*block_args| yield(*block_args) }
        else
          calculate(:sum, *args)
        end
      end
      
      def count(*args)
        column_name, options = @reflection.klass.send(:construct_count_options_from_args, *args)
        if @reflection.options[:uniq]
          # This is needed because 'SELECT count(DISTINCT *)..' is not valid sql statement.
          column_name = "#{@reflection.quoted_table_name}.#{@reflection.klass.primary_key}" if column_name == :all
          options.merge!(:distinct => true) 
        end
        @reflection.klass.send(:with_scope, construct_scope) { @reflection.klass.count(column_name, options) } 
      end

      protected
        def method_missing(method, *args)
          if @target.respond_to?(method) || (!@reflection.klass.respond_to?(method) && Class.respond_to?(method))
            if block_given?
              super { |*block_args| yield(*block_args) }
            else
              super
            end
          else
            @reflection.klass.send(:with_scope, construct_scope) do
              if block_given?
                @reflection.klass.send(method, *args) { |*block_args| yield(*block_args) }
              else
                @reflection.klass.send(method, *args)
              end
            end
          end
        end

        def find_target
          records = @reflection.klass.find(:all,
            :select     => construct_select,
            :conditions => construct_conditions,
            :from       => construct_from,
            :joins      => construct_joins,
            :order      => @reflection.options[:order],
            :limit      => @reflection.options[:limit],
            :group      => @reflection.options[:group],
            :include    => @reflection.options[:include] || @reflection.source_reflection.options[:include]
          )

          records.uniq! if @reflection.options[:uniq]
          records
        end

        # Construct attributes for associate pointing to owner.
        def construct_owner_attributes(reflection)
          if as = reflection.options[:as]
            { "#{as}_id" => @owner.id,
              "#{as}_type" => @owner.class.base_class.name.to_s }
          else
            { reflection.primary_key_name => @owner.id }
          end
        end

        # Construct attributes for :through pointing to owner and associate.
        def construct_join_attributes(associate)
          join_attributes = construct_owner_attributes(@reflection.through_reflection).merge(@reflection.source_reflection.primary_key_name => associate.id)
          if @reflection.options[:source_type]
            join_attributes.merge!(@reflection.source_reflection.options[:foreign_type] => associate.class.base_class.name.to_s)
          end
          join_attributes
        end

        # Associate attributes pointing to owner, quoted.
        def construct_quoted_owner_attributes(reflection)
          if as = reflection.options[:as]
            { "#{as}_id" => @owner.quoted_id,
              "#{as}_type" => reflection.klass.quote_value(
                @owner.class.base_class.name.to_s,
                reflection.klass.columns_hash["#{as}_type"]) }
          else
            { reflection.primary_key_name => @owner.quoted_id }
          end
        end

        # Build SQL conditions from attributes, qualified by table name.
        def construct_conditions
          table_name = @reflection.through_reflection.quoted_table_name
          conditions = construct_quoted_owner_attributes(@reflection.through_reflection).map do |attr, value|
            "#{table_name}.#{attr} = #{value}"
          end
          conditions << sql_conditions if sql_conditions
          "(" + conditions.join(') AND (') + ")"
        end

        def construct_from
          @reflection.quoted_table_name
        end

        def construct_select(custom_select = nil)
          selected = custom_select || @reflection.options[:select] || "#{@reflection.quoted_table_name}.*"
        end

        def construct_joins(custom_joins = nil)
          polymorphic_join = nil
          if @reflection.source_reflection.macro == :belongs_to
            reflection_primary_key = @reflection.klass.primary_key
            source_primary_key     = @reflection.source_reflection.primary_key_name
            if @reflection.options[:source_type]
              polymorphic_join = "AND %s.%s = %s" % [
                @reflection.through_reflection.quoted_table_name, "#{@reflection.source_reflection.options[:foreign_type]}",
                @owner.class.quote_value(@reflection.options[:source_type])
              ]
            end
          else
            reflection_primary_key = @reflection.source_reflection.primary_key_name
            source_primary_key     = @reflection.klass.primary_key
            if @reflection.source_reflection.options[:as]
              polymorphic_join = "AND %s.%s = %s" % [
                @reflection.quoted_table_name, "#{@reflection.source_reflection.options[:as]}_type",
                @owner.class.quote_value(@reflection.through_reflection.klass.name)
              ]
            end
          end

          "INNER JOIN %s ON %s.%s = %s.%s %s #{@reflection.options[:joins]} #{custom_joins}" % [
            @reflection.through_reflection.table_name,
            @reflection.table_name, reflection_primary_key,
            @reflection.through_reflection.table_name, source_primary_key,
            polymorphic_join
          ]
        end

        def construct_scope
          { :create => construct_owner_attributes(@reflection),
            :find   => { :from        => construct_from,
                         :conditions  => construct_conditions,
                         :joins       => construct_joins,
                         :include     => @reflection.options[:include],
                         :select      => construct_select,
                         :order       => @reflection.options[:order],
                         :limit       => @reflection.options[:limit] } }
        end

        def construct_sql
          case
            when @reflection.options[:finder_sql]
              @finder_sql = interpolate_sql(@reflection.options[:finder_sql])

              @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = #{@owner.quoted_id}"
              @finder_sql << " AND (#{conditions})" if conditions
          end

          if @reflection.options[:counter_sql]
            @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
          elsif @reflection.options[:finder_sql]
            # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
            @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
            @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
          else
            @counter_sql = @finder_sql
          end
        end

        def conditions
          @conditions = build_conditions unless defined?(@conditions)
          @conditions
        end

        def build_conditions
          association_conditions = @reflection.options[:conditions]
          through_conditions = @reflection.through_reflection.options[:conditions]
          source_conditions = @reflection.source_reflection.options[:conditions]
          uses_sti = !@reflection.through_reflection.klass.descends_from_active_record?

          if association_conditions || through_conditions || source_conditions || uses_sti
            all = []

            [association_conditions, through_conditions, source_conditions].each do |conditions|
              all << interpolate_sql(sanitize_sql(conditions)) if conditions
            end

            all << build_sti_condition if uses_sti

            all.map { |sql| "(#{sql})" } * ' AND '
          end
        end

        def build_sti_condition
          "#{@reflection.through_reflection.quoted_table_name}.#{@reflection.through_reflection.klass.inheritance_column} = #{@reflection.klass.quote_value(@reflection.through_reflection.klass.name.demodulize)}"
        end

        alias_method :sql_conditions, :conditions

        def has_cached_counter?
          @owner.attribute_present?(cached_counter_attribute_name)
        end

        def cached_counter_attribute_name
          "#{@reflection.name}_count"
        end
    end
  end
end

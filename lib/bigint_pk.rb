require 'bigint_pk/version'
require 'bigint_pk/railtie'
require 'active_record'

module BigintPk
  extend self

  def enable!
    install_patches!
  end

  private

  module DefaultBigintPrimaryKey
    def primary_key(name, type = :primary_key, **options)
      if type == :primary_key
        super(name, :bigint, **options)
      else
        super
      end
    end
  end

  module PostgresBigintPrimaryKey
    def primary_key(name, type = :primary_key, **options)
      if type == :primary_key
        super(name, :bigserial, **options)
      else
        super
      end
    end
  end

  module MysqlBigintPrimaryKey
    def primary_key(name, type = :primary_key, **options)
      if type == :primary_key
        options[:auto_increment] = true unless options.key?(:default)
        super(name, ActiveRecord::VERSION::MAJOR < 5 ? :primary_key : :bigint, **options)
      else
        super
      end
    end
  end

  module DefaultBigintForeignKeyReferences
    def references(*args)
      options = args.extract_options!
      options.reverse_merge! limit: 8
      # Limit shouldn't affect "#{col}_type" column in polymorphic reference.
      # But don't change value if it isn't simple 'true'.
      # Examples:
      #   t.references :subject, null: false, polymorphic: true ==> t.integer :subject_id, limit: 8, null: false
      #                                                             t.string  :subject_type, null: false
      #   t.references :subject, polymorphic: { limit: 120 }    ==> t.integer :subject_id, limit: 8
      #                                                             t.string  :subject_type, limit: 120
      options[:polymorphic] = options.except(:polymorphic, :limit) if options[:polymorphic] == true
      super(*args, options)
    end
  end

  def install_patches!
    ca   = ActiveRecord::ConnectionAdapters
    conf = ca::ConnectionSpecification::Resolver.new(ActiveRecord::Base.configurations).configurations[Rails.env]

    if conf['adapter'] == 'postgresql'
      pk_module = PostgresBigintPrimaryKey
      ca::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'
    elsif conf['adapter'] =~ /mysql\d+/
      pk_module = MysqlBigintPrimaryKey
      ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigint(20) auto_increment PRIMARY KEY'
      ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:integer] = { :name => "bigint", :limit => 6 }
    end

    [ca::TableDefinition,
     ca::Table].each do |abstract_table_type|
      abstract_table_type.prepend(pk_module || DefaultBigintPrimaryKey)
      abstract_table_type.prepend(DefaultBigintForeignKeyReferences)
    end
  end
end

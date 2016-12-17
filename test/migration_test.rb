require 'minitest/autorun'
require 'bigint_pk'
require 'rails'

class MigrationTest < Minitest::Test
  def setup
    super
    Rails.env = 'test'
    ActiveRecord::Base.configurations = YAML.load_file(File.join(File.dirname(__FILE__), 'conf', "#{ENV['ADAPTER'] || 'mysql2'}.yml"))
    ActiveRecord::Base.establish_connection(:test)
    BigintPk.enable!
  end

  def teardown
    super
    ActiveRecord::Base.connection.drop_table("foo") rescue nil
  end

  def test_creating_a_table_use_bigint_as_primary_key
    connection = ActiveRecord::Base.connection
    connection.create_table('foo')
    columns = connection.columns(:foo)
    assert_equal ['id'], columns.map(&:name)
    assert_equal [:integer], columns.map(&:type)
    if ActiveRecord::Base.configurations['test']['adapter'] == 'postgresql'
      assert_equal ['bigint'], columns.map(&:sql_type)
      assert_equal "nextval('foo_id_seq'::regclass)", connection.exec_query("SELECT column_default FROM information_schema.columns WHERE table_name = 'foo' AND column_name = 'id'").first['column_default']
    else
      assert_equal ['bigint(20)'], columns.map(&:sql_type)
      assert_equal '`id` bigint(20) NOT NULL AUTO_INCREMENT', connection.exec_query('SHOW CREATE TABLE `foo`').first['Create Table'].match(/`id`[^,\n]+/)[0]
    end
    assert_equal [8], columns.map(&:limit)
  end

  def test_creating_a_reference_column_uses_bigint
    connection = ActiveRecord::Base.connection
    connection.create_table('foo') do |td|
      td.references :post
    end
    columns = connection.columns(:foo)
    assert_equal ['id', 'post_id'], columns.map(&:name)
    assert_equal [:integer, :integer], columns.map(&:type)
    if ActiveRecord::Base.configurations['test']['adapter'] == 'postgresql'
      assert_equal ['bigint', 'bigint'], columns.map(&:sql_type)
    else
      assert_equal ['bigint(20)', 'bigint(20)'], columns.map(&:sql_type)
    end
    assert_equal [8, 8], columns.map(&:limit)
  end
end

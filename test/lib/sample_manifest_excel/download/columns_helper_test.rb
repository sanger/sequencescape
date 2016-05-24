require_relative '../../../test_helper.rb'

class ColumnHelperTest < ActiveSupport::TestCase

	class Chairs

		include SampleManifestExcel::Download::ColumnHelper

	end


	test "set_columns should add column names" do
		names = ['column1', 'column2']
		Chairs.set_columns(names)
		assert_equal names, Chairs.column_names
		Chairs.set_columns(names)
		assert_equal ['column1', 'column2', 'column1', 'column2'], Chairs.column_names
	end


end
require "test_helper"

class SubmissionTemplateTest < ActiveSupport::TestCase
  context "A Order Template" do
    setup do
      @template = SubmissionTemplate.new(:name => "default order", :submission_class_name => "Order")
    end

    should "be able to create a new order" do
      order = @template.new_order
      assert order
      assert order.is_a?(Order)

    end
  end

  context "A Order" do
    setup do
      @workflow = Factory :submission_workflow,:key => 'microarray_genotyping'
      @order = Order.new(:workflow => @workflow)
    end
    context "with a comment" do
      setup do
        @comment = "my comment"
        @order.comments = @comment
      end

      should "be savable as a template" do
        template = SubmissionTemplate.new_from_submission("template 1", @order)
        assert template
        assert template.is_a?(SubmissionTemplate)
      end

      context "saved as a template" do
        setup do
          @template_name = "template 2"
          @template = SubmissionTemplate.new_from_submission(@template_name, @order)
        end

        should "set the name to template" do
          assert_equal @template_name, @template.name
        end

        should "set parameters to template" do
          assert @template.submission_parameters
          assert_equal @comment, @template.submission_parameters[:comments]
        end
      end
    end
    # context "with input_field_infos set with a selection" do
    #   setup do
    #     @field = FieldInfo.new(:kind => "Selection", :selection => ["a", "b"])
    #     @order.set_input_field_infos([@field])
    #   end

    #   context "saved as template" do
    #     setup do
    #       template = SubmissionTemplate.new_from_submission("template 2", @order)
    #       template.save!
    #       template_id = template.id

    #       @loaded_template = SubmissionTemplate.find(template_id)
    #     end

    #     should "load the parameters properly" do
    #       order = @loaded_template.new_order
    #       assert_equal 1, order.input_field_infos.size
    #       assert_equal @field.selection, order.input_field_infos.first.selection
    #     end
    #   end
    # end
    context "without input_field_infos" do
      setup do

        @test_request_typ_b = Factory :library_creation_request_type
        @test_request_typ_b
        @test_request_type  = Factory :sequencing_request_type
        @order.request_types = [@test_request_typ_b, @test_request_type]
        @order.request_type_ids_list = [[@test_request_typ_b.id],[@test_request_type.id]]
      end

      should "load the parameters properly" do
        assert_equal 6, @order.input_field_infos.size
        assert_equal [37, 54, 76, 108], field('Read length').selection
        assert_equal 54, field('Read length').default_value
        assert_equal ['Standard'], field('Library type').selection
        assert_equal 'Standard', field('Library type').default_value
      end
    end
  end

  def field(field_name)
    @order.input_field_infos.detect {|ifi| ifi.display_name == field_name} || raise("#{field_name} field not found")
  end
end


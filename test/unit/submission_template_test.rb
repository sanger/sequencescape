require "test_helper"

class SubmissionTemplateTest < ActiveSupport::TestCase
  context "A Order Template" do
    setup do
      @template = SubmissionTemplate.new(:name => "default order", :submission_class_name => "Order")
    end

    should "be able to create a new order" do
      order = @template.new_submission
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
    context "with input_field_infos set with a selection" do
      setup do
        @field = FieldInfo.new(:kind => "Selection", :selection => ["a", "b"])
        @order.set_input_field_infos([@field])
      end

      context "saved as template" do
        setup do
          template = SubmissionTemplate.new_from_submission("template 2", @order)
          template.save!
          template_id = template.id

          @loaded_template = SubmissionTemplate.find(template_id)
        end

        should "load the parameters properly" do
          order = @loaded_template.new_submission
          assert_equal 1, order.input_field_infos.size
          assert_equal @field.selection, order.input_field_infos.first.selection
        end
      end
    end
  end
end


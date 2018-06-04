
require 'test_helper'

class SearchesControllerTest < ActionController::TestCase
  context 'Searches controller' do
    setup do
      @controller = SearchesController.new
      @request    = ActionController::TestRequest.create(@controller)
    end

    should_require_login

    context 'searching (when logged in)' do
      setup do
        @user = FactoryBot.create :user
        @controller.stubs(:logged_in?).returns(@user)
        session[:user] = @user.id

        @study = FactoryBot.create :study, name: 'FindMeStudy'
        @study2 = FactoryBot.create :study, name: 'Another study'
        @sample = FactoryBot.create :sample, name: 'FindMeSample'
        @asset = FactoryBot.create(:sample_tube, name: 'FindMeAsset')
        @asset_group_to_find = FactoryBot.create :asset_group, name: 'FindMeAssetGroup', study: @study
        @asset_group_to_not_find = FactoryBot.create :asset_group, name: 'IgnoreAssetGroup'

        @submission = FactoryBot.create :submission, name: 'FindMe'
        @ignore_submission = FactoryBot.create :submission, name: 'IgnoreMeSub'

        @sample_with_supplier_name = FactoryBot.create :sample, sample_metadata_attributes: { supplier_name: 'FindMe' }
        @sample_with_accession_number = FactoryBot.create :sample, sample_metadata_attributes: { sample_ebi_accession_number: 'FindMe' }
      end
      context '#index' do
        context 'with the valid search' do
          setup do
            get :index, params: { q: 'FindMe' }
          end

          should respond_with :success

          context 'results' do
            define_method(:assert_link_to) do |url|
              assert_select 'a[href=?]', url
            end

            define_method(:deny_link_to) do |url|
              assert_select 'a[href=?]', url, count: 0
            end

            should 'contain a link to the study that was found' do
              assert_link_to study_path(@study)
            end

            should 'not contain a link to the study that was not found' do
              deny_link_to study_path(@study2)
            end

            should 'contain a link to the submission that was found' do
              assert_link_to submission_path(@submission)
            end

            should 'not contain a link to the submission that was not found' do
              deny_link_to submission_path(@ignore_submission)
            end

            should 'contain a link to the sample that was found' do
              assert_link_to sample_path(@sample)
            end

            should 'contain a link to the sample that was found by supplier name' do
              assert_link_to sample_path(@sample_with_supplier_name)
            end

            should 'contain a link to the sample that was found by sample_ebi_accession_number' do
              assert_link_to sample_path(@sample_with_accession_number)
            end

            should 'contain a link to the asset that was found' do
              assert_link_to asset_path(@asset)
            end

            should 'contain a link to the asset_group that was found' do
              assert_link_to study_asset_group_path(@asset_group_to_find.study, @asset_group_to_find)
            end
          end
        end

        context 'with a too short query' do
          setup do
            get :index, params: { q: 'A' }
          end

          should 'set the flash' do
            assert_equal 'Queries should be at least 3 characters long', @controller.flash.now[:error]
          end
        end
      end
    end
  end
end

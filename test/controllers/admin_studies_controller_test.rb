# frozen_string_literal: true

require 'test_helper'

module Admin
  class StudiesControllerTest < ActionController::TestCase
    context 'Studies controller' do
      setup do
        @controller = Admin::StudiesController.new
        @request = ActionController::TestRequest.create(@controller)
      end

      should_require_login

      context 'management UI' do
        setup do
          @user = FactoryBot.create(:admin)
          @study = FactoryBot.create(:study)
          @request_type = FactoryBot.create(:request_type)
          session[:user] = @user.id
          @emails = ActionMailer::Base.deliveries
          @emails.clear
        end

        context '#managed_update (without changes)' do
          setup do
            get :managed_update,
                params: {
                  id: @study.id,
                  study: {
                    name: @study.name,
                    reference_genome_id: @study.reference_genome_id
                  }
                }
          end

          should 'not send an email' do
            assert_empty @emails
          end

          should redirect_to('admin studies path') { "/admin/studies/#{@study.id}" }
        end

        context 'without a data_access_coordinator role' do
          should "not change 'ethically_approved'" do
            Rails.logger.info '******** First Request'
            put :managed_update, params: { id: @study.id, study: { name: @study.name, ethically_approved: '1' } }
            @study.reload

            assert_not @study.ethically_approved
          end
        end

        context 'with a data_access_coordinator role' do
          setup { @user.roles << create(:data_access_coordinator_role) }

          should "change 'ethically_approved'" do
            Rails.logger.info '******** First Request'
            put :managed_update, params: { id: @study.id, study: { name: @study.name, ethically_approved: '1' } }
            @study.reload

            assert @study.ethically_approved
          end
        end

        context '#update when sapio restrictions enabled' do
          context 'and study is mastered_in_sapio' do
            setup do
              Flipper.enable(:y26_171_enable_sapio_mastered_study_restrictions)
              Study.where(id: @study.id).update_all(mastered_in_sapio: true)
              @study.reload
              put :update, params: { id: @study.id, study: { name: 'Updated Name' } }
            end

            teardown do
              Flipper.disable(:y26_171_enable_sapio_mastered_study_restrictions)
            end

            should redirect_to('study information page') { study_information_path(@study) }

            should 'display error flash' do
              assert flash[:error] == 'This study is mastered and controlled in SAPIO and cannot be updated.'
            end
          end

          context 'and study is not mastered_in_sapio' do
            setup do
              Flipper.enable(:y26_171_enable_sapio_mastered_study_restrictions)
              @study.update(mastered_in_sapio: false)
              put :update, params: { id: @study.id, study: { name: 'Updated Name' } }
            end

            teardown do
              Flipper.disable(:y26_171_enable_sapio_mastered_study_restrictions)
            end

            should 'display success notice' do
              assert flash.now[:notice] == 'Your study has been updated'
            end
          end
        end

        context '#update when sapio restrictions disabled' do
          setup do
            Flipper.disable(:y26_171_enable_sapio_mastered_study_restrictions)
            Study.where(id: @study.id).update_all(mastered_in_sapio: true)
            @study.reload
            put :update, params: { id: @study.id, study: { name: 'Updated Name' } }
          end

          should 'allow update even for mastered study' do
            assert flash.now[:notice] == 'Your study has been updated'
          end
        end
      end
    end
  end
end

shared_examples 'it requires login' do |*actions|
  params = (actions.pop if actions.last.is_a?(Hash)) || {}
  actions << :index if actions.empty?
  actions.each do |action|
    describe action.to_s do
      context 'when logged in' do
        setup do
          session[:user] = create(:user)
          begin
            get action, params
          rescue AbstractController::ActionNotFound
            flunk "Testing for an unknown action: #{action}"
          rescue ActiveRecord::RecordNotFound
            assert true
          rescue ActionView::MissingTemplate
            flunk "Missing template for #{action} action"
          end
        end
        it 'does not redirect' do
          expect(@response.code).not_to be_in(300..307)
        end
      end
      context 'when not logged in' do
        setup do
          session[:user] = nil
          if params[:resource].present?
            resource = params.delete(:resource)
            params['id'] = (create resource).id
          end
          if params[:parent].present?
            parent_resource = params.delete(:parent)
            params["#{parent_resource}_id"] = (create parent_resource).id
          end
          begin
            get action, params: params
          rescue AbstractController::ActionNotFound
            flunk "Testing for an unknown action: #{action}"
          end
        end
        it { is_expected.to redirect_to login_path }
      end
    end
  end
end

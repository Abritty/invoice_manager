require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe 'GET #new' do
    it 'should get new registration page' do
      get :new
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end

    it 'should assign a new user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      let(:valid_attributes) do
        {
          user: {
            first_name: "John",
            last_name: "Doe",
            email_address: "john.doe@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it 'should create a new user' do
        expect {
          post :create, params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it 'should redirect to root path' do
        post :create, params: valid_attributes
        expect(response).to redirect_to(root_path)
      end

      it 'should set success notice' do
        post :create, params: valid_attributes
        expect(flash[:notice]).to eq("Account created successfully!")
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) do
        {
          user: {
            first_name: "",
            last_name: "",
            email_address: "invalid-email",
            password: "123",
            password_confirmation: "456"
          }
        }
      end

      it 'should not create a new user' do
        expect {
          post :create, params: invalid_attributes
        }.not_to change(User, :count)
      end

      it 'should render new template' do
        post :create, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end


      it 'should not save user with invalid attributes' do
        expect {
          post :create, params: invalid_attributes
        }.not_to change(User, :count)
      end
    end
  end
end

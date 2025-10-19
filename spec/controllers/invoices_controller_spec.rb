require 'rails_helper'

RSpec.describe InvoicesController, type: :controller do
  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:valid_attributes) do
    {
      buyer_name: "Acme Corp",
      phone_number: "+1 202 555 1234",
      invoice_issue_date: Date.current,
      expiry_date: Date.current + 30.days,
      amount: 100.50,
      state: :sent
    }
  end

  let(:invalid_attributes) do
    {
      buyer_name: "",
      phone_number: "invalid",
      invoice_issue_date: Date.current + 1.day,
      expiry_date: Date.current - 1.day,
      amount: -10,
      state: :sent  # Use valid state, let other validations fail
    }
  end

  before do
    # Mock authentication by setting up Current model
    session = double('session', user: user)
    allow(Current).to receive(:session).and_return(session)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns user's invoices" do
      invoice = user.invoices.create!(valid_attributes)
      get :index
      expect(assigns(:invoices)).to include(invoice)
    end

    it "does not include other users' invoices" do
      other_user = User.create!(
        first_name: "Jane",
        last_name: "Smith",
        email_address: "jane.smith@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      other_invoice = other_user.invoices.create!(valid_attributes)
      get :index
      expect(assigns(:invoices)).not_to include(other_invoice)
    end

    it "filters by search parameter" do
      user.invoices.create!(valid_attributes.merge(buyer_name: "Acme Corp"))
      user.invoices.create!(valid_attributes.merge(buyer_name: "Beta Inc"))
      get :index, params: { search: "Acme" }
      expect(assigns(:invoices).count).to eq(1)
    end

    it "filters by state parameter" do
      user.invoices.create!(valid_attributes.merge(state: :sent))
      user.invoices.create!(valid_attributes.merge(state: :paid))
      get :index, params: { state: "sent" }
      expect(assigns(:invoices).count).to eq(1)
    end

    it "sorts by buyer_name ascending" do
      user.invoices.create!(valid_attributes.merge(buyer_name: "Zeta Corp"))
      user.invoices.create!(valid_attributes.merge(buyer_name: "Alpha Corp"))
      get :index, params: { sort: "buyer_name_asc" }
      expect(assigns(:invoices).first.buyer_name).to eq("Alpha Corp")
    end

    it "paginates results" do
      # Create 15 invoices to test pagination (default per_page is 10)
      15.times do |i|
        user.invoices.create!(valid_attributes.merge(buyer_name: "Company #{i}"))
      end
      
      get :index, params: { page: 1 }
      expect(assigns(:invoices).count).to eq(10)
      expect(assigns(:invoices).current_page).to eq(1)
      
      get :index, params: { page: 2 }
      expect(assigns(:invoices).count).to eq(5)
      expect(assigns(:invoices).current_page).to eq(2)
    end
  end

  describe "GET #show" do
    it "returns a successful response" do
      invoice = user.invoices.create!(valid_attributes)
      get :show, params: { id: invoice.id }
      expect(response).to be_successful
    end

    it "assigns the requested invoice" do
      invoice = user.invoices.create!(valid_attributes)
      get :show, params: { id: invoice.id }
      expect(assigns(:invoice)).to eq(invoice)
    end

    it "raises error for other user's invoice" do
      other_user = User.create!(
        first_name: "Jane",
        last_name: "Smith",
        email_address: "jane.smith@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      other_invoice = other_user.invoices.create!(valid_attributes)
      expect {
        get :show, params: { id: other_invoice.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new invoice" do
      get :new
      expect(assigns(:invoice)).to be_a_new(Invoice)
      expect(assigns(:invoice).user).to eq(user)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new invoice" do
        expect {
          post :create, params: { invoice: valid_attributes }
        }.to change(Invoice, :count).by(1)
      end

      it "redirects to the created invoice" do
        post :create, params: { invoice: valid_attributes }
        expect(response).to redirect_to(Invoice.last)
      end

      it "sets the invoice state to sent by default" do
        post :create, params: { invoice: valid_attributes }
        expect(Invoice.last.state).to eq('sent')
      end
    end

    context "with invalid parameters" do
      it "does not create a new invoice" do
        expect {
          post :create, params: { invoice: invalid_attributes }
        }.not_to change(Invoice, :count)
      end

      it "renders the new template" do
        post :create, params: { invoice: invalid_attributes }
        expect(response).to render_template(:new)
      end

      it "returns unprocessable entity status" do
        post :create, params: { invoice: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET #edit" do
    it "returns a successful response" do
      invoice = user.invoices.create!(valid_attributes)
      get :edit, params: { id: invoice.id }
      expect(response).to be_successful
    end

    it "assigns the requested invoice" do
      invoice = user.invoices.create!(valid_attributes)
      get :edit, params: { id: invoice.id }
      expect(assigns(:invoice)).to eq(invoice)
    end
  end

  describe "PUT #update" do
    let(:invoice) { user.invoices.create!(valid_attributes) }

    context "with valid parameters" do
      let(:new_attributes) do
        { buyer_name: "Updated Corp", amount: 200.00 }
      end

      it "updates the requested invoice" do
        put :update, params: { id: invoice.id, invoice: new_attributes }
        invoice.reload
        expect(invoice.buyer_name).to eq("Updated Corp")
        expect(invoice.amount).to eq(200.00)
      end

      it "redirects to the invoice" do
        put :update, params: { id: invoice.id, invoice: new_attributes }
        expect(response).to redirect_to(invoice)
      end
    end

    context "with invalid parameters" do
      it "does not update the invoice" do
        original_name = invoice.buyer_name
        put :update, params: { id: invoice.id, invoice: invalid_attributes }
        invoice.reload
        expect(invoice.buyer_name).to eq(original_name)
      end

      it "renders the edit template" do
        put :update, params: { id: invoice.id, invoice: invalid_attributes }
        expect(response).to render_template(:edit)
      end

      it "returns unprocessable entity status" do
        put :update, params: { id: invoice.id, invoice: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested invoice" do
      invoice = user.invoices.create!(valid_attributes)
      expect {
        delete :destroy, params: { id: invoice.id }
      }.to change(Invoice, :count).by(-1)
    end

    it "redirects to the invoices list" do
      invoice = user.invoices.create!(valid_attributes)
      delete :destroy, params: { id: invoice.id }
      expect(response).to redirect_to(invoices_url)
    end
  end
end

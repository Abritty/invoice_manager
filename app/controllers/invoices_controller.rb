class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy]

  def index
    @invoices = current_user.invoices.includes(:user)
    
    # Search functionality
    if params[:search].present?
      @invoices = @invoices.search_by_buyer_name(params[:search])
    end
    
    # Filter by state
    if params[:state].present? && Invoice.states.key?(params[:state])
      @invoices = @invoices.filter_by_state(params[:state])
    end
    
    # Apply sorting
    @invoices = @invoices.sort_invoices_by(params[:sort])
    
    # Apply pagination
    @invoices = @invoices.page(params[:page])
  end

  def show
  end

  def new
    @invoice = current_user.invoices.build
  end

  def create
    @invoice = current_user.invoices.build(invoice_params)
    @invoice.state = :sent # Default state

    if @invoice.save
      redirect_to @invoice, notice: 'Invoice was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: 'Invoice was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_url, notice: 'Invoice was successfully deleted.'
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:buyer_name, :phone_number, :invoice_issue_date, :expiry_date, :amount, :state)
  end
end

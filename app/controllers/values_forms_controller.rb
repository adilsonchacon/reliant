class ValuesFormsController < ApplicationController
  before_action :set_values_form, only: [:show, :update, :destroy]

  # GET /values_forms
  def index
    @values_forms = ValuesForm.all

    render json: @values_forms
  end

  # GET /values_forms/1
  def show
    render json: @values_form
  end

  # POST /values_forms
  def create
    @values_form = ValuesForm.new(values_form_params)

    if @values_form.save
      render json: @values_form, status: :created, location: @values_form
    else
      render json: @values_form.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /values_forms/1
  def update
    if @values_form.update(values_form_params)
      render json: @values_form
    else
      render json: @values_form.errors, status: :unprocessable_entity
    end
  end

  # DELETE /values_forms/1
  def destroy
    @values_form.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_values_form
      @values_form = ValuesForm.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def values_form_params
      params.require(:values_form).permit(:json_forms_id, :content_yaml)
    end
end

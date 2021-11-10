class ValuesFormsController < ApplicationController
  before_action :set_values_form, only: [:show, :update, :destroy]

  # GET /json_forms/1/values_forms/
  def index
    @values_forms = ValuesForm.where(json_form_id: params[:json_form_id])

    render json: @values_forms
  end

  # GET /json_forms/1/values_forms/1
  def show
    render json: @values_form
  end

  # POST /json_forms/1/values_forms
  def create
    @values_form = ValuesForm.new(values_form_params)
    @values_form.json_form_id = params[:json_form_id]

    if @values_form.save
      render json: @values_form, status: :created
    else
      render json: { errors: @values_form.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /json_forms/1/values_forms/1
  def update
    if @values_form.update(values_form_params)
      render json: @values_form
    else
      render json: { errors: @values_form.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /json_forms/1/values_forms/1
  def destroy
    @values_form.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_values_form
      @values_form = ValuesForm.where(id: params[:id], json_form_id: params[:json_form_id]).first
    end

    # Only allow a list of trusted parameters through.
    def values_form_params
      params.require(:values_form).permit(inputs: [])
    end
end

class JsonFormsController < ApplicationController
  before_action :set_json_form, only: [:show, :update, :destroy, :generate_structure_for_html_form]

  # GET /json_forms
  def index
    @json_forms = JsonForm.all

    render json: @json_forms
  end

  # GET /json_forms/1
  def show
    render json: @json_form
  end

  # POST /json_forms
  def create
    @json_form = JsonForm.new(json_form_params)

    if @json_form.save
      render json: @json_form, status: :created, location: @json_form
    else
      render json: { errors: @json_form.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /json_forms/1
  def update
    if @json_form.update(json_form_params)
      render json: @json_form
    else
      render json: { errors: @json_form.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /json_forms/1
  def destroy
    @json_form.destroy

    render json: {}
  end

  def generate_structure_for_html_form
    render json: @json_form.generate_structure_for_html_form
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_json_form
      @json_form = JsonForm.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def json_form_params
      params.require(:json_form).permit(:content, :content_yaml)
    end
end

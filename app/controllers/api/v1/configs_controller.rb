class Api::V1::ConfigsController < ApplicationController
  before_action :set_config, only: :update

  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :parse_error

  # POST /configs
  def create
    config = current_user.configs.create!(get_config)

    render json: { message: "Config #{config.name} was successfully created." }, status: :created
  end

  # PATCH/PUT /configs/name
  def update
    if params.has_key?(:config) && params[:config].present?
      @config.update!(get_config)
    elsif params.has_key?(:"entity types") || params.has_key?(:"relation types")
      @config.update!(body: get_body)
    end

    render json: { message: "Config #{@config.name} was successfully updated." }, status: :ok
  end

  private

  def set_config
    @config = current_user.configs.friendly.find(params[:id])
  end

  def get_config
    config = params.require(:config).permit(:name, :description, :body, :is_public)
    config[:body] = get_body(config)
    config
  end

  def get_body(config)
    body_obj =
      if params.has_key?(:config) && params[:config].present?
        if config[:body].present?
          JSON.parse config[:body]
        else
          {}
        end
      elsif params.has_key?(:"entity types") || params.has_key?(:"relation types")
        {
          "autocompletion_ws": params.fetch(:"autocompletion_ws", ""),
          "entity types": params.fetch(:"entity types", []),
          "relation types": params.fetch(:"relation types", []),
          "attribute types": params.fetch(:"attribute types", []),
          "delimiter characters": params.fetch(:"delimiter characters", []),
          "non-edge characters": params.fetch(:"non-edge characters", [])
        }.keep_if{|k, v| v.present?}
      else
        nil
      end

      body_obj.nil? ? nil : JSON.pretty_generate(body_obj)
  end

  def handle_standard_error(e)
    render json: { error: e.message }, status: :internal_server_error
  end

  def record_invalid(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def record_not_unique(e)
    render json: { error: 'Config name has already been taken.' }, status: :conflict
  end

  def parse_error(e)
    render json: { error: 'Invalid JSON format', details: e.message }, status: :bad_request
  end

end

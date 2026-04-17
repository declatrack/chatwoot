require './config/environment'
params = ActionController::Parameters.new({
  components: [
    { type: "BODY", example: { body_text_named_params: [ { param_name: "test", example: "test" } ] } }
  ]
})
puts params[:components].class.name
request_body = { components: params[:components] }
puts request_body.to_json

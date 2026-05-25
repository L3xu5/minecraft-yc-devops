resource "yandex_api_gateway" "main" {
  name        = var.gateway_name
  description = "HTTP API for Minecraft status (Cloud Function proxy)"

  spec = <<-OPENAPI
    openapi: 3.0.0
    info:
      title: Minecraft Status API
      version: 1.0.0
    paths:
      /:
        get:
          x-yc-apigateway-integration:
            type: cloud_functions
            function_id: ${var.function_id}
            service_account_id: ${var.service_account_id}
          operationId: status
      /health:
        get:
          x-yc-apigateway-integration:
            type: cloud_functions
            function_id: ${var.function_id}
            service_account_id: ${var.service_account_id}
          operationId: health
  OPENAPI
}

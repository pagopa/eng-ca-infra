# API Gateway definition
resource "aws_api_gateway_rest_api" "this" {

  name = "${var.environment}-${var.apigw_name}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  disable_execute_api_endpoint = false #TODO change this

}

##
## Route53
##
#region
resource "aws_api_gateway_domain_name" "api" {
  count                    = data.external.get_ns_primary.result.nameservers == "" ? 0 : 1
  domain_name              = "${var.app_api_subdomain_name}.${var.app_primary_domain_name}"
  regional_certificate_arn = aws_acm_certificate_validation.api_validation[0].certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  security_policy = "TLS_1_2"
}

resource "aws_api_gateway_base_path_mapping" "api" {
  count       = data.external.get_ns_primary.result.nameservers == "" ? 0 : 1
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.v1.stage_name
  domain_name = aws_api_gateway_domain_name.api[0].domain_name
}

resource "aws_route53_record" "api" {
  count   = data.external.get_ns_primary.result.nameservers == "" ? 0 : 1
  name    = aws_api_gateway_domain_name.api[0].domain_name
  type    = "A"
  zone_id = aws_route53_zone.this.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api[0].regional_zone_id
  }
}
#endregion

##
## Resources
##
#region

# /intermediate
resource "aws_api_gateway_resource" "intermediate" {
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = var.apigw_intermediate_path
  rest_api_id = aws_api_gateway_rest_api.this.id
}

## /intermediate/{intermediate_id}
resource "aws_api_gateway_resource" "intermediate_param_path" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.intermediate.id
  path_part   = "{${var.apigw_intermediate_param_path}}"
}


### .../List 
#region

# /intermediate/{intermediate_id}/certificates
resource "aws_api_gateway_resource" "list" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.intermediate_param_path.id
  path_part   = var.apigw_list_path_certificates
}

resource "aws_api_gateway_method" "list" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.list.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method_response" "list" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.list.id
  http_method = aws_api_gateway_method.list.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "list" {
  http_method             = aws_api_gateway_method.list.http_method
  integration_http_method = "POST"
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.list.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_ca.invoke_arn
}

resource "aws_api_gateway_integration_response" "list" {
  depends_on  = [aws_api_gateway_integration.list]
  http_method = aws_api_gateway_method.list.http_method
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.list.id
  status_code = aws_api_gateway_method_response.list.status_code

  response_templates = {
    "application/json" = "",
    "application/xml"  = ""
  }
}

#endregion

### .../Get
#region

# /intermediate/{intermediate_id}/certificate/{serial_number}
resource "aws_api_gateway_resource" "get_revoke" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.sign_csr.id
  path_part   = "{${var.apigw_get_revoke_path}}"
}

resource "aws_api_gateway_method" "get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.get_revoke.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method_response" "get" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.get_revoke.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "get" {
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.get_revoke.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_ca.invoke_arn
}

resource "aws_api_gateway_integration_response" "get" {
  depends_on  = [aws_api_gateway_integration.get]
  http_method = aws_api_gateway_method.get.http_method
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.get_revoke.id
  status_code = aws_api_gateway_method_response.get.status_code

  response_templates = {
    "application/json" = "",
    "application/xml"  = ""
  }
}

#endregion


### .../Revoke
#region

resource "aws_api_gateway_method" "revoke" {
  authorization = "NONE"
  http_method   = "DELETE"
  resource_id   = aws_api_gateway_resource.get_revoke.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method_response" "revoke" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.get_revoke.id
  http_method = aws_api_gateway_method.revoke.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "revoke" {
  http_method             = aws_api_gateway_method.revoke.http_method
  integration_http_method = "POST"
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.get_revoke.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_ca.invoke_arn
}

resource "aws_api_gateway_integration_response" "revoke" {
  depends_on  = [aws_api_gateway_integration.revoke]
  http_method = aws_api_gateway_method.revoke.http_method
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.get_revoke.id
  status_code = aws_api_gateway_method_response.revoke.status_code

  response_templates = {
    "application/json" = "",
    "application/xml"  = ""
  }
}

#endregion

### .../Sign CSR
#region

# /intermediate/{intermediate_id}/certificate
resource "aws_api_gateway_resource" "sign_csr" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.intermediate_param_path.id
  path_part   = var.apigw_sign_path
}

resource "aws_api_gateway_method" "sign_csr" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.sign_csr.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method_response" "sign_csr" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.sign_csr.id
  http_method = aws_api_gateway_method.sign_csr.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "sign_csr" {
  http_method             = aws_api_gateway_method.sign_csr.http_method
  integration_http_method = "POST"
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.sign_csr.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_ca.invoke_arn
}

resource "aws_api_gateway_integration_response" "sign_csr" {
  depends_on  = [aws_api_gateway_integration.sign_csr]
  http_method = aws_api_gateway_method.sign_csr.http_method
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.sign_csr.id
  status_code = aws_api_gateway_method_response.sign_csr.status_code

  response_templates = {
    "application/json" = "",
    "application/xml"  = ""
  }
}

#endregion

### .../Crl
#region
# /intermediate/{intermediate_id}/crl
resource "aws_api_gateway_resource" "crl" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.intermediate_param_path.id
  path_part   = var.apigw_crl_path
}

resource "aws_api_gateway_method" "crl" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.crl.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method_response" "crl" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.crl.id
  http_method = aws_api_gateway_method.crl.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "crl" {
  http_method             = aws_api_gateway_method.crl.http_method
  integration_http_method = "POST"
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.crl.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_ca.invoke_arn
}

resource "aws_api_gateway_integration_response" "crl" {
  depends_on  = [aws_api_gateway_integration.crl]
  http_method = aws_api_gateway_method.crl.http_method
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.crl.id
  status_code = aws_api_gateway_method_response.crl.status_code

  response_templates = {
    "application/json" = "",
    "application/xml"  = ""
  }
}
#endregion

# Login
#region

# login
resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = var.apigw_login_path
}

resource "aws_api_gateway_method" "login" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.login.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method_response" "login" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.login.id
  http_method = aws_api_gateway_method.login.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "login" {
  http_method             = aws_api_gateway_method.login.http_method
  integration_http_method = "POST"
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.login.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_ca.invoke_arn
}

resource "aws_api_gateway_integration_response" "login" {
  depends_on  = [aws_api_gateway_integration.login]
  http_method = aws_api_gateway_method.login.http_method
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.login.id
  status_code = aws_api_gateway_method_response.login.status_code

  response_templates = {
    "application/json" = "",
    "application/xml"  = ""
  }
}

#endregion

#endregion


# Deployment
#region 

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_rest_api.this.*,

      aws_api_gateway_resource.intermediate.*,
      aws_api_gateway_resource.intermediate_param_path.*,
      aws_api_gateway_resource.list.*,
      aws_api_gateway_resource.get_revoke.*,
      aws_api_gateway_resource.sign_csr.*,
      aws_api_gateway_resource.login.*,
      aws_api_gateway_resource.crl.*,

      aws_api_gateway_method.list.*,
      aws_api_gateway_method.get.*,
      aws_api_gateway_method.sign_csr.*,
      aws_api_gateway_method.revoke.*,
      aws_api_gateway_method.crl.*,
      aws_api_gateway_method.login.*,

      aws_api_gateway_method_response.list.*,
      aws_api_gateway_method_response.get.*,
      aws_api_gateway_method_response.sign_csr.*,
      aws_api_gateway_method_response.revoke.*,
      aws_api_gateway_method_response.crl.*,
      aws_api_gateway_method_response.login.*,

      aws_api_gateway_integration.list.*,
      aws_api_gateway_integration.get.*,
      aws_api_gateway_integration.sign_csr.*,
      aws_api_gateway_integration.revoke.*,
      aws_api_gateway_integration.crl.*,
      aws_api_gateway_integration.login.*,

      aws_api_gateway_integration_response.list.*,
      aws_api_gateway_integration_response.get.*,
      aws_api_gateway_integration_response.sign_csr.*,
      aws_api_gateway_integration_response.revoke.*,
      aws_api_gateway_integration_response.crl.*,
      aws_api_gateway_integration_response.login.*

    ]))
  }
}

resource "aws_cloudwatch_log_group" "api_v1" {
  name              = "/apigw/${aws_api_gateway_rest_api.this.name}/${var.apigw_stage_name}"
  retention_in_days = 90
}

# Stage
resource "aws_api_gateway_stage" "v1" {
  deployment_id        = aws_api_gateway_deployment.this.id
  rest_api_id          = aws_api_gateway_rest_api.this.id
  stage_name           = var.apigw_stage_name
  xray_tracing_enabled = true
  access_log_settings {
    format          = "$context.identity.sourceIp,$context.requestTime,$context.httpMethod,$context.path,$context.protocol,$context.status,$context.responseLength,$context.requestId,$context.extendedRequestId,$context.integrationErrorMessage"
    destination_arn = aws_cloudwatch_log_group.api_v1.arn
  }
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.v1.stage_name
  method_path = "*/*"
  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

#endregion

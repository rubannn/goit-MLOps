resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "validate" {
  function_name    = "${var.project_name}-validate"
  filename         = "${path.module}/lambda/validate.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/validate.zip")
  handler          = "validate.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
}

resource "aws_lambda_function" "log_metrics" {
  function_name    = "${var.project_name}-log-metrics"
  filename         = "${path.module}/lambda/log_metrics.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/log_metrics.zip")
  handler          = "log_metrics.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
}

resource "aws_iam_role" "step_functions_exec" {
  name = "${var.project_name}-sfn-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_invoke_lambda" {
  name = "${var.project_name}-sfn-invoke-lambda"
  role = aws_iam_role.step_functions_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.validate.arn,
        aws_lambda_function.log_metrics.arn,
      ]
    }]
  })
}

resource "aws_sfn_state_machine" "train_pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.step_functions_exec.arn

  definition = jsonencode({
    Comment = "Simplified ML training workflow: validate data, then log metrics"
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type     = "Task"
        Resource = aws_lambda_function.validate.arn
        Next     = "LogMetrics"
      }
      LogMetrics = {
        Type     = "Task"
        Resource = aws_lambda_function.log_metrics.arn
        End      = true
      }
    }
  })
}

output "state_machine_arn" {
  description = "ARN of the Step Function state machine, used by GitLab CI to start executions"
  value       = aws_sfn_state_machine.train_pipeline.arn
}

output "validate_lambda_name" {
  value = aws_lambda_function.validate.function_name
}

output "log_metrics_lambda_name" {
  value = aws_lambda_function.log_metrics.function_name
}

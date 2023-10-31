output "code_build_project_name" {
  value = aws_codebuild_project.main.name
}


output "code_build_project_arn" {
  value = aws_codebuild_project.main.arn
}

output "role_arn" {
  value = var.role_name != null ? data.aws_iam_role.main[0].arn : aws_iam_role.main[0].arn
}

output "role_name" {
  value = aws_iam_role.main[0].name
}
package main

# mfa must be enabled for Admin User
warn contains message if {
  some i
  user := input.users[i]
  user.role == "Administrator"
  not user.mfa_enabled
  message := sprintf("Admin user '%s' does not have MFA enabled.", [user.username])
}

# This rule denies policies that include action = "*"
warn contains message if {
  statement := input.resource.aws_iam_policy[_].policy.Statement[_]
  statement.Action == "*"
  message = "Wildcard action '*' is not allowed."
}

# This rule denies policies that include Resource = "*"
warn contains message if {
  statement := input.resource.aws_iam_policy[_].policy.Statement[_]
  statement.Resource == "*"
  message = "Wildcard resource '*' is not allowed."
}

# Any action that contains "*" if policy is simple string
warn contains message if {
  statement := input.resource.aws_iam_policy[_].policy.Statement[_]
  is_string(statement.Action)
  contains(statement.Action, "*")
  message := sprintf("Action '%s' contains wildcard '*' which is not allowed.", [statement.Action])
}

# Any action that contains "*" if policy is an array
warn contains message if {
  statement := input.resource.aws_iam_policy[_].policy.Statement[_]
  is_array(statement.Action)
  action := statement.Action[_]
  contains(action, "*")
  message := sprintf("Action '%s' contains wildcard '*' which is not allowed.", [action])
}
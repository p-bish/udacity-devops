terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=2.46.0"
    }
  }
}
provider "azurerm" {
  features {}
}
data "azurerm_subscription" "current" {}

resource "azurerm_policy_definition" "tagpolicy" {
  name = "tagging-policy-def"
  policy_type = "Custom"
  mode = "Indexed"
  display_name = "Require tags on all resources"

  metadata = <<METADATA
    {
      "category": "General"
    }
METADATA
  policy_rule = <<POLICY_RULE
{
  "if":{
    "value": "[empty(field('tags'))]",
    "equals": true
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
/*   parameters = <<PARAMETERS
{
  "tagName": {
    "type": "String",
    "metadata": {
      "displayName": "Tag Name",
      "description": "Name of the tag"
    }
  }
}
PARAMETERS */
}

resource "azurerm_subscription_policy_assignment" "tagpolicy" {
  name = "tagging-policy"
  policy_definition_id = azurerm_policy_definition.tagpolicy.id
  subscription_id = data.azurerm_subscription.current.id
  /* parameters = <<PARAMDEF
{
  "parameters": {
    "tagName": {
      "value": "Created by"
    }
  }
}
PARAMDEF */
}
variable "site_name" {
  type = string
}

variable "AMI_ID" {
  type = string
}

variable "EC2_Size" {
  type = string
}

variable "VPC_Id" {
  type = string
}

variable "Public_SubnetID1" {
  type = string
}

variable "Public_SubnetID2" {
  type = string
}

variable "Private_SubnetID1" {
  type = string
}

variable "Master_private_ip" {
  type = string
}

variable "Follower_private_ip" {
  type = string
}

variable "Primary_cidr" {
  type = string
}

variable "Secondary_cidr" {
  type = string
}

variable "EIP_Static_ID" {
  type = string
}

variable "Primary_PublicIP" {
  type = string
}

variable "Secondary_PublicIP" {
  type = string
}

variable "Pre_Shared_Key" {
  type = string
}
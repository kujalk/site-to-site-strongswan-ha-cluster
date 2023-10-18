
#Create a role for EC2 instance

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_role" {
  name = "${var.site_name}_EC2_Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    "Description" = "${var.site_name}_EC2_Role"
  }
}


#Policy for the above role to oontact EC2 instance and to trigger SSM document
resource "aws_iam_policy" "policy" {
  name        = "${var.site_name}_EC2_Policy"
  description = "${var.site_name} : Allow EC2 instance to access the EIP and RouteTable"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EIPActions"
        Effect = "Allow"
        Action = [
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ReleaseAddress",
          "ec2:DescribeAddresses",
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Actions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
        ]
        Resource = "*"
      },
      {
        Sid    = "ENIActions"
        Effect = "Allow"
        Action = [
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
        ]
        Resource = "*"
      },
      {
        Sid    = "RouteTableActions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeRouteTables",
          "ec2:ReplaceRoute",
          "ec2:CreateRoute",
        ]
        Resource = "*"
      }
    ]
  })
}


#Attach the SSM policy to the above EC2 role
resource "aws_iam_role_policy_attachment" "EC2-Attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.policy.arn
}

#Attach the SSM policy to the above EC2 role
resource "aws_iam_role_policy_attachment" "SSM-Attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#Create an EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.site_name}_EC2_IAM_Profile"
  role = aws_iam_role.ec2_role.name
}
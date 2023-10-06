
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
resource "aws_iam_policy" "ssmpolicy" {
  name        = "${var.site_name}_EC2_SSM_Policy"
  description = "${var.site_name} : Allow EC2 instance to access the S3 buckets"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/strongswan/config/*"
        }
    ]
}
EOF
}


#Attach the SSM policy to the above EC2 role
resource "aws_iam_role_policy_attachment" "EC2-Attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ssmpolicy.arn
}

#Create an EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.site_name}_EC2_IAM_Profile"
  role = aws_iam_role.ec2_role.name
}

# network

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "personal-cluster-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"] #, "eu-west-1c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"] #, "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"] #, "10.1.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = true
  propagate_public_route_tables_vgw = true
  propagate_private_route_tables_vgw = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
		cluster     = "test"
  }
}

# compute

resource "aws_launch_template" "master" {
  name_prefix            = "personal_cluster_master"
  image_id               = "ami-06358f49b5839867c"
  instance_type          = "t3a.micro"
  key_name               = "personal-test-cluster"

  # instance_market_options {
  #   market_type = "spot"
  # }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.node_profile.name}"
  }

	vpc_security_group_ids = ["${aws_security_group.public_node_sg.id}", "${module.vpc.default_security_group_id}"]

  user_data = "${base64encode(file("./scripts/master-user-data"))}"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Terraform   = "true"
      Environment = "dev"
			Name        = "personal-test-cluster-master-node"
    }
  }
}

resource "aws_autoscaling_group" "master" {
	name                = "personal-cluster-master-asg"
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_zone_identifier = "${module.vpc.public_subnets}"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1


  launch_template {
    id      = "${aws_launch_template.master.id}"
    version = "$Latest"
  }
}

resource "aws_launch_template" "private" {
  name_prefix            = "personal_cluster_private"
  image_id               = "ami-06358f49b5839867c"
  instance_type          = "t3a.micro"
  key_name               = "personal-test-cluster"

  # instance_market_options {
  #   market_type = "spot"
  # }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.node_profile.name}"
  }

	vpc_security_group_ids = ["${aws_security_group.public_node_sg.id}", "${module.vpc.default_security_group_id}"]

  user_data = "${base64encode(file("./scripts/private-user-data"))}"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Terraform   = "true"
      Environment = "dev"
			Name        = "personal-test-cluster-private-node"
    }
  }
}

resource "aws_autoscaling_group" "private" {
	name                = "personal-cluster-private-asg"
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_zone_identifier = "${module.vpc.public_subnets}"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = "${aws_launch_template.private.id}"
    version = "$Latest"
  }
}

resource "aws_launch_template" "public" {
  name_prefix            = "personal_cluster_public"
  image_id               = "ami-06358f49b5839867c"
  instance_type          = "t3a.micro"
  key_name               = "personal-test-cluster"

  # instance_market_options {
  #   market_type = "spot"
  # }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.node_profile.name}"
  }

	vpc_security_group_ids = ["${aws_security_group.public_node_sg.id}", "${module.vpc.default_security_group_id}"]

  user_data = "${base64encode(file("./scripts/public-user-data"))}"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Terraform   = "true"
      Environment = "dev"
			Name        = "personal-test-cluster-public-node"
    }
  }
}

resource "aws_autoscaling_group" "public" {
	name                = "personal-cluster-public-asg"
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_zone_identifier = "${module.vpc.public_subnets}"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = "${aws_launch_template.public.id}"
    version = "$Latest"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "public_node_sg" {
  name        = "allow_ssh_and_http"
  description = "Allow appropriate inbound traffic"
	vpc_id      = "${module.vpc.vpc_id}"

	ingress {
		from_port   = 22
    to_port     = 22
    protocol    = "tcp"
		cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
	}
	ingress {
		from_port   = 443
    to_port     = 443
    protocol    = "tcp"
		cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
	}
	ingress {
		from_port   = 80
    to_port     = 80
    protocol    = "tcp"
		cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
	}
}
# IAM

resource "aws_iam_instance_profile" "node_profile" {
  name = "personal_cluster_instance_profile"
  role = "${aws_iam_role.node_role.name}"
}

resource "aws_iam_role" "node_role" {
  name = "personal_cluster_node_role"
  path = "/personal-cluster/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "node_r53_policy_attachment" {
  role       = "${aws_iam_role.node_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_policy" "instance_s3_policy" {
    name        = "test-policy"
    description = "A test policy"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
				"arn:aws:s3:::personal-cluster-scripts/*",
				"arn:aws:s3:::personal-cluster-scripts"
			]    
    }
	]
}
EOF
}

resource "aws_iam_role_policy_attachment" "node_s3_policy_attachment" {
  role       = "${aws_iam_role.node_role.name}"
  policy_arn = "${aws_iam_policy.instance_s3_policy.arn}"
}

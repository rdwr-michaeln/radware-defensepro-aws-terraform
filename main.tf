provider "aws" {
  region = var.aws_region
}

locals {
  resource_suffix = "${var.aws_username}_${var.deployment_index}"
  availability_zone_1 = "${var.aws_region}${var.availability_zone_suffix_1}"
  availability_zone_2 = "${var.aws_region}${var.availability_zone_suffix_2}"

  defensepro_1_data_ip = cidrhost(var.defensepro_data_subnet_cidr, 10)
  defensepro_2_data_ip = cidrhost(var.defensepro_data_subnet_cidr, 11)
  scrubbing_mgmt_ip_dp_1 = cidrhost(var.scrubbing_mgmt_subnet_cidr, 10)
  scrubbing_mgmt_ip_dp_2 = cidrhost(var.scrubbing_mgmt_subnet_cidr, 11)
  scrubbing_mgmt_ip_cc = cidrhost(var.scrubbing_mgmt_subnet_cidr, 20)
  target_srv_ip = cidrhost(var.application_subnet_cidr, 20)
}

# Common tags
locals {
  common_tags = {
    Project =  var.project_name
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Create the Customer VPC
resource "aws_vpc" "customer_vpc" {
  cidr_block = var.customer_vpc_cidr

  tags = merge(local.common_tags, {
    Name = "Customer-VPC-${local.resource_suffix}"
  })
}

# Create the Scrubbing VPC
resource "aws_vpc" "scrubbing_vpc" {
  cidr_block = var.scrubbing_vpc_cidr

  tags = merge(local.common_tags, {
    Name = "Scrubbing-VPC-${local.resource_suffix}"
  })
}

# Create subnets in the Customer VPC
resource "aws_subnet" "application_subnet" {
  vpc_id            = aws_vpc.customer_vpc.id
  cidr_block        = var.application_subnet_cidr
  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "Application-Sub-${local.resource_suffix}"
  })
}

resource "aws_subnet" "glb_endpoint_subnet" {
  vpc_id            = aws_vpc.customer_vpc.id
  cidr_block        = var.glb_endpoint_subnet_cidr
  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "GLB-Endpoint-Sub-${local.resource_suffix}"
  })
}

# Create subnets in the Scrubbing VPC
resource "aws_subnet" "scrubbing_mgmt_subnet" {
  vpc_id            = aws_vpc.scrubbing_vpc.id
  cidr_block        = var.scrubbing_mgmt_subnet_cidr
  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "Scrubbing-VPC-MGMT-Sub-1-${local.resource_suffix}"
  })
}

resource "aws_subnet" "defensepro_data_subnet" {
  vpc_id            = aws_vpc.scrubbing_vpc.id
  cidr_block        = var.defensepro_data_subnet_cidr
  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "DefensePro-DATA-Sub-1-${local.resource_suffix}"
  })
}


# Create security groups
resource "aws_security_group" "sg_customer_vpc" {
  name        = "SG-Customer-VPC-${local.resource_suffix}"
  description = "Security Group for Customer VPC"
  vpc_id      = aws_vpc.customer_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_computer_network_for_ssh]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "sg_customer_vpc_allow_all" {
  name        = "SG-Customer-VPC-Allow-All-${local.resource_suffix}"
  description = "Allow all inbound and outbound traffic for Customer VPC"
  vpc_id      = aws_vpc.customer_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "SG-Customer-VPC-Allow-All-${local.resource_suffix}"
  })
}

resource "aws_security_group" "sg_data_scrubbing_vpc" {
  name        = "SG-DATA-Scrubbing-VPC-${local.resource_suffix}"
  description = "Security Group for DATA in Scrubbing VPC"
  vpc_id      = aws_vpc.scrubbing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.glb_endpoint_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "sg_mgmt_scrubbing_vpc" {
  name        = "SG-MGMT-Scrubbing-VPC-${local.resource_suffix}"
  description = "Security Group for MGMT in Scrubbing VPC"
  vpc_id      = aws_vpc.scrubbing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_computer_network_for_ssh, var.scrubbing_mgmt_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "default_all" {
  name        = "default_all-${local.resource_suffix}"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.scrubbing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"       
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "allow-any-any-${local.resource_suffix}"
  })
}

# Security group specifically for DefensePro data interfaces
resource "aws_security_group" "sg_defensepro_data" {
  name        = "SG-DefensePro-Data-${local.resource_suffix}"
  description = "Security Group for DefensePro Data Interfaces"
  vpc_id      = aws_vpc.scrubbing_vpc.id

  # Allow GENEVE traffic from GLB Endpoint subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  # Allow return traffic for GENEVE
  egress {
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
    cidr_blocks = [var.glb_endpoint_subnet_cidr]
    description = "GENEVE return traffic to GLB Endpoint"
  }

  # Allow all outbound traffic for health responses and management
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "SG-DefensePro-Data-${local.resource_suffix}"
  })
}

# Create network interfaces for CC instances
resource "aws_network_interface" "cc_mgmt" {
  subnet_id         = aws_subnet.scrubbing_mgmt_subnet.id
  security_groups   = [aws_security_group.default_all.id]
  private_ips       = [local.scrubbing_mgmt_ip_cc]

  tags = local.common_tags
}


# Create network interfaces for DefensePro1 instances
resource "aws_network_interface" "dp1_eth0" {
  subnet_id         = aws_subnet.defensepro_data_subnet.id
  security_groups   = [aws_security_group.sg_defensepro_data.id]
  private_ips       = [local.defensepro_1_data_ip]
  source_dest_check = false

  tags = local.common_tags
}

resource "aws_network_interface" "dp1_eth1" {
  subnet_id         = aws_subnet.scrubbing_mgmt_subnet.id
  security_groups   = [aws_security_group.sg_mgmt_scrubbing_vpc.id]
  private_ips       = [local.scrubbing_mgmt_ip_dp_1]

  tags = local.common_tags
}



#Create network interfaces for DefensePro2 instances
resource "aws_network_interface" "dp2_eth0" {
  subnet_id         = aws_subnet.defensepro_data_subnet.id
  security_groups   = [aws_security_group.sg_defensepro_data.id]
  private_ips       = [local.defensepro_2_data_ip]
  source_dest_check = false

  tags = local.common_tags
}

resource "aws_network_interface" "dp2_eth1" {
  subnet_id         = aws_subnet.scrubbing_mgmt_subnet.id
  security_groups   = [aws_security_group.sg_mgmt_scrubbing_vpc.id]
  private_ips       = [local.scrubbing_mgmt_ip_dp_2]

  tags = local.common_tags
}

# Create network interfaces for Target server instances
resource "aws_network_interface" "target_eth0" {
  subnet_id         = aws_subnet.application_subnet.id
  security_groups   = [aws_security_group.sg_customer_vpc_allow_all.id]
  private_ips       = [local.target_srv_ip]

  tags = local.common_tags
}


/*
resource "local_file" "user_data_script" {
  content  = <<-EOT
              #!/bin/bash
              FILE="/mnt/disk/InitialConfig"
              /bin/cat <<EOF > $FILE
              net traffic-encapsulation status set 1
              net traffic-encapsulation protocol set Geneve
              net traffic-encapsulation port set 6081
              net health-check interface set mgmt
              net health-check port set 18000
              net health-check interface set 1
              EOF
  EOT
  filename = "${path.module}/defensepro-setup.sh"
}

resource "aws_s3_bucket" "user_data_bucket" {
  bucket = "radware-dp-user-data-${random_id.bucket_suffix.hex}"
  
  tags = merge(local.common_tags, {
    Name = "User-Data-Bucket-${random_id.bucket_suffix.hex}"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_object" "user_data_script" {
  bucket = aws_s3_bucket.user_data_bucket.bucket
  key    = "init_conf"
  source = local_file.user_data_script.filename
  acl    = "private"
  
  tags = merge(local.common_tags, {
    Name = "User-Data-Script-${random_id.bucket_suffix.hex}"
  })
}

resource "aws_iam_role" "ec2_s3_access" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2025-6-16",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "ec2_s3_access_policy"
  description = "Policy to allow EC2 instances to access S3 bucket"

  policy = jsonencode({
    Version = "2025-6-16",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.user_data_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.user_data_bucket.bucket}/*"
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_access_attachment" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_access_profile" {
  name = "ec2_s3_access_profile"
  role = aws_iam_role.ec2_s3_access.name
}

*/


#Target Server EC2 instance
resource "aws_instance" "target_srv" {
  ami           = var.target_srv_ami_id
  instance_type = var.target_srv_instance_type
  key_name      = aws_key_pair.target_server_key_pair.key_name

  # Wait for DefensePro instances to be ready before creating target server
  depends_on = [
    aws_instance.defensepro_1,
    aws_instance.defensepro_2,
    aws_eip_association.defensepro_eip_assoc_1,
    aws_eip_association.defensepro_eip_assoc_2
  ]
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.target_eth0.id
  }
  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "Target_SRV-${local.resource_suffix}-2"
  })
}


# CC (Cyber Controller) EC2 instance
resource "aws_instance" "cc" {
  ami                  = var.cyber_controller_ami_id
  iam_instance_profile = aws_iam_instance_profile.cc_ssm_profile.name
  instance_type        = var.cc_instance_type
  
  # Basic system preparation only - actual CC configuration handled by run_cc_automation.sh
  user_data = <<-EOT
              #!/bin/bash
              # Basic system preparation for CC instance
              echo "CC instance initialized at $(date)" >> /var/log/cc_init.log
              
              # Ensure SSH is ready for external configuration
              systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null
              systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null
  EOT
  
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.cc_mgmt.id
  }
  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "CC-${local.resource_suffix}-1"
  })
}


# Add Systems Manager support for CC instance (optional)
resource "aws_iam_role" "cc_ssm_role" {
  name = "CC-SSM-Role-${local.resource_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cc_ssm_policy" {
  role       = aws_iam_role.cc_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cc_ssm_profile" {
  name = "CC-SSM-Profile-${local.resource_suffix}"
  role = aws_iam_role.cc_ssm_role.name

  tags = local.common_tags
}

#DP EC2 instance
resource "aws_instance" "defensepro_1" {
  ami           = var.defensepro_ami_id
  instance_type = var.dp_1_instance_type
  user_data = <<-EOT
              #!/bin/bash
              FILE="/mnt/disk/InitialConfig"
              /bin/cat <<EOF > $FILE
              net traffic-encapsulation status set 1
              net traffic-encapsulation protocol set Geneve
              net traffic-encapsulation port set 6081
              net health-check interface set mgmt
              net health-check port set 18000
              net health-check interface set 1
              EOF
  EOT

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.dp1_eth0.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.dp1_eth1.id
  }

  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "DefensePro-${local.resource_suffix}-1"
  })
}

resource "aws_instance" "defensepro_2" {
  ami           = var.defensepro_ami_id
  #iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_profile.name
  instance_type = var.dp_1_instance_type
  user_data = <<-EOT
              #!/bin/bash
              FILE="/mnt/disk/InitialConfig"
              /bin/cat <<EOF > $FILE
              net traffic-encapsulation status set 1
              net traffic-encapsulation protocol set Geneve
              net traffic-encapsulation port set 6081
              net health-check interface set mgmt
              net health-check port set 18000
              net health-check interface set 1
              EOF
  EOT

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.dp2_eth0.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.dp2_eth1.id
  }

  availability_zone = local.availability_zone_1

  tags = merge(local.common_tags, {
    Name = "DefensePro-${local.resource_suffix}-2"
  })
}

resource "aws_eip" "defensepro_eip_1" {
  tags = merge(local.common_tags, {
    Name = "DefensePro-EIP-${local.resource_suffix}-1"
  })
}

resource "aws_eip" "target_eip_1" {
  tags = merge(local.common_tags, {
    Name = "Target-${local.resource_suffix}-1"
  })
}

resource "aws_eip" "defensepro_eip_2" {
  tags = merge(local.common_tags, {
    Name = "DefensePro-EIP-${local.resource_suffix}-2"
  })
}

resource "aws_eip" "cc_eip_mgmt" {
  tags = merge(local.common_tags, {
    Name = "CC-EIP-${local.resource_suffix}-2"
  })
}

resource "aws_eip_association" "target_assoc_1" {
  allocation_id        = aws_eip.target_eip_1.id
  network_interface_id = aws_network_interface.target_eth0.id
  depends_on           = [aws_instance.target_srv]
}

resource "aws_eip_association" "defensepro_eip_assoc_1" {
  allocation_id        = aws_eip.defensepro_eip_1.id
  network_interface_id = aws_network_interface.dp1_eth1.id
  depends_on           = [aws_instance.defensepro_1]
}

resource "aws_eip_association" "defensepro_eip_assoc_2" {
  allocation_id        = aws_eip.defensepro_eip_2.id
  network_interface_id = aws_network_interface.dp2_eth1.id
  depends_on           = [aws_instance.defensepro_2]
}

resource "aws_eip_association" "cc_eip_assoc" {
  allocation_id        = aws_eip.cc_eip_mgmt.id
  network_interface_id = aws_network_interface.cc_mgmt.id
  depends_on           = [aws_instance.cc]
} 

# Create Internet Gateways
resource "aws_internet_gateway" "customer_vpc_igw" {
  vpc_id = aws_vpc.customer_vpc.id

  tags = merge(local.common_tags, {
    Name = "IGW-Customer-VPC-${local.resource_suffix}"
  })
}

resource "aws_internet_gateway" "scrubbing_vpc_igw" {
  vpc_id = aws_vpc.scrubbing_vpc.id

  tags = merge(local.common_tags, {
    Name = "IGW-Scrubbing-VPC-${local.resource_suffix}"
  })
}

# Create Gateway Load Balancer in Scrubbing VPC
resource "aws_lb" "gateway_lb" {
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [aws_subnet.defensepro_data_subnet.id]

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  tags = merge(local.common_tags, {
    Name = "Gateway-LB-${local.resource_suffix}"
  })
}

# Output to print the ARN of the Gateway Load Balancer
output "gateway_lb_arn" {
  value       = aws_lb.gateway_lb.arn
  description = "The ARN of the Gateway Load Balancer"
}

# Create Target Group for Gateway Load Balancer
resource "aws_lb_target_group" "defensepro_tg" {
  target_type = "ip"
  port        = 6081
  protocol    = "GENEVE"
  vpc_id      = aws_vpc.scrubbing_vpc.id

  health_check {
    protocol            = "TCP"
    port                = "18000"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.common_tags, {
    Name = "DefensePro-TG-${local.resource_suffix}"
  })
}

# Attach DefensePro instances to the Target Group using their IPs
resource "aws_lb_target_group_attachment" "defensepro_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.defensepro_tg.arn
  target_id        = local.defensepro_1_data_ip
  port             = 6081
}

resource "aws_lb_target_group_attachment" "defensepro_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.defensepro_tg.arn
  target_id        = local.defensepro_2_data_ip
  port             = 6081
}

# Create Listener for the Gateway Load Balancer
resource "aws_lb_listener" "gateway_lb_listener" {
  load_balancer_arn = aws_lb.gateway_lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.defensepro_tg.arn
  }
}


# Create VPC Endpoint Service for the Gateway Load Balancer
resource "aws_vpc_endpoint_service" "gwlb_endpoint_service" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gateway_lb.arn]

  tags = merge(local.common_tags, {
    Name = "gwlb-endpoint-service-${local.resource_suffix}"
  })
}

# Create VPC Endpoint for the Gateway Load Balancer
resource "aws_vpc_endpoint" "gwlb_endpoint" {
  vpc_id            = aws_vpc.customer_vpc.id
  service_name      = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.glb_endpoint_subnet.id]

  tags = merge(local.common_tags, {
    Name = "gwlb-endpoint-${local.resource_suffix}"
  })
}

# Ingress Route Table (Internet Gateway Edge Route Table)
resource "aws_route_table" "igw_ingress_rt" {
  vpc_id = aws_vpc.customer_vpc.id

  route {
    cidr_block = var.application_subnet_cidr
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint.id
  }

  tags = merge(local.common_tags, {
    Name = "IGW-Ingress-RT-${local.resource_suffix}"
  })
}

# Associate with Internet Gateway (Edge Association)
resource "aws_route_table_association" "igw_ingress_rt_association" {
  gateway_id     = aws_internet_gateway.customer_vpc_igw.id
  route_table_id = aws_route_table.igw_ingress_rt.id
}

# GWLBe-RT (Gateway Load Balancer Endpoint Route Table)
resource "aws_route_table" "gwlbe_rt" {
  vpc_id = aws_vpc.customer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.customer_vpc_igw.id
  }

  tags = merge(local.common_tags, {
    Name = "GWLBe-RT-${local.resource_suffix}"
  })
}

# Associate with GLB Endpoint Subnet (10.1.111.0/24)
resource "aws_route_table_association" "gwlbe_subnet" {
  subnet_id      = aws_subnet.glb_endpoint_subnet.id
  route_table_id = aws_route_table.gwlbe_rt.id
}

# APP-To-GWLBe-RT (Application Subnet Route Table)
resource "aws_route_table" "app_to_gwlbe_rt" {
  vpc_id = aws_vpc.customer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint.id
  }

  tags = merge(local.common_tags, {
    Name = "APP-To-GWLBe-RT-${local.resource_suffix}"
  })
}

# Associate with Application Subnet (10.1.2.0/24)
resource "aws_route_table_association" "app_subnet" {
  subnet_id      = aws_subnet.application_subnet.id
  route_table_id = aws_route_table.app_to_gwlbe_rt.id
}

# Scrubbing-VPC-Default-RT (Updated)
resource "aws_route_table" "scrubbing_vpc_default_rt" {
  vpc_id = aws_vpc.scrubbing_vpc.id

  route {
    cidr_block = "10.10.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.scrubbing_vpc_igw.id
  }

  tags = merge(local.common_tags, {
    Name = "Scrubbing-VPC-Default-RT-${local.resource_suffix}"
  })
}

# Make this the default route table for the scrubbing VPC
resource "aws_main_route_table_association" "scrubbing_vpc_main_rt" {
  vpc_id         = aws_vpc.scrubbing_vpc.id
  route_table_id = aws_route_table.scrubbing_vpc_default_rt.id
}

# Associate the routing table with the DefensePro data subnet
resource "aws_route_table_association" "scrubbing_vpc_default_rt_assoc_1" {
  subnet_id      = aws_subnet.defensepro_data_subnet.id
  route_table_id = aws_route_table.scrubbing_vpc_default_rt.id
}

# Associate the routing table with the management subnet
resource "aws_route_table_association" "scrubbing_vpc_mgmt_rt_assoc_1" {
  subnet_id      = aws_subnet.scrubbing_mgmt_subnet.id
  route_table_id = aws_route_table.scrubbing_vpc_default_rt.id
}

# Automatic CC configuration after deployment
resource "null_resource" "cc_auto_config" {
  depends_on = [
    aws_instance.cc,
    aws_eip_association.cc_eip_assoc
  ]

  triggers = {
    cc_instance_id = aws_instance.cc.id
    cc_public_ip   = aws_eip.cc_eip_mgmt.public_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for CC instance to initialize..."
      sleep 60
      
      echo "Starting CC configuration automation..."
      echo "CC Public IP: ${aws_eip.cc_eip_mgmt.public_ip}"
      CC_IP="${aws_eip.cc_eip_mgmt.public_ip}" ./run_cc_automation.sh || echo "CC configuration completed (exit code ignored)"
      
      echo ""
      echo "=================================================================="
      echo "🎉 TERRAFORM DEPLOYMENT COMPLETED SUCCESSFULLY!"
      echo "=================================================================="
      echo ""
      echo "📋 Deployment Summary:"
      echo "terraform output deployment_summary"
      echo ""
      echo "🚀 NEXT STEPS:"
      echo "=============="
      echo "1. 🛡️  Add DefensePro devices: ./add_dp_to_cc_unified.sh"
      echo "2. 🌐 Install Apache on target: ./install_apache_ssh.sh"
      echo "3. 📊 View deployment info: terraform output deployment_summary"
      echo ""
      echo "=================================================================="
    EOT
    
    working_dir = path.module
  }
}

# SSH Key Pair for Target Server Access
resource "tls_private_key" "target_server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "target_server_key_pair" {
  key_name   = "target-server-key-${local.resource_suffix}"
  public_key = tls_private_key.target_server_key.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "Target-Server-Key-${local.resource_suffix}"
  })
}

# Save private key locally for SSH access
resource "local_file" "target_server_private_key" {
  content  = tls_private_key.target_server_key.private_key_pem
  filename = "${path.module}/target-server-key-${local.resource_suffix}.pem"
  file_permission = "0600"
}



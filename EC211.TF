provider aws {
    region = "ap-south-1"
    profile = "nikhil1898"
}

#CREATING THE VPC 
resource "aws_vpc" "t3vpc" {
    cidr_block = "192.168.0.0/16"
    enable_dns_hostnames = "true"
    tags = {
        Name = "task3vpc"
    }
}

#CREATING TWO DIFFERENT LABS OR SUBNET IN THE VPC

#THIS ONE IS FOR THE PUBLIC SUBNET
resource "aws_subnet" "t3sub1" {
    vpc_id = "${aws_vpc.t3vpc.id}"
    cidr_block = "192.168.3.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch  = "true"
    tags = {
        Name = "t3sub1"
    }
}

#THIS ONE IS FOR THE PRIVATE SUBNET
resource "aws_subnet" "t3sub2" {
    vpc_id = "${aws_vpc.t3vpc.id}"
    cidr_block = "192.168.4.0/24"
    availability_zone = "ap-south-1a"
    tags = {
        Name = "t3sub2"
    }
}


#THIS IS FOR CREATING THE INTERNET GATEWAY
resource "aws_internet_gateway" "t3igw1" {
    vpc_id = "${aws_vpc.t3vpc.id}"
    tags = {
        Name = "t3igw1"
    }
}

#THIS IS FOR CREATING THE ROUTING TABLE
resource "aws_route_table" "t3rt" {
    vpc_id = "${aws_vpc.t3vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.t3igw1.id}"  
    }
}

#ATTACHING ROUTE TABLE TO THE SUBNET CREATED
resource "aws_route_table_association" "attachrt" {
    subnet_id = "${aws_subnet.t3sub1.id}"
    route_table_id = "${aws_route_table.t3rt.id}"
}

#CREATING SECURITY GROUPS FOR SUBNET 1 AND 2
#SECURITY GROUP FOR WORDPRESS INSTANCES
resource "aws_security_group" "sg1"{
    name = "allow_tcp_wp"
    description = "Allow tcp and ssh to the instances launched"
    vpc_id = "${aws_vpc.t3vpc.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

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

   tags = {
       Name = "sg1"
   }
}

#SECURITY GROUP FOR MYSQL INSTANCES
resource "aws_security_group" "sg2" {
    name = "allow_tcp_mysql"
    description = "allow only the traffic from the wordpress instances to connect"
    vpc_id = "${aws_vpc.t3vpc.id}"
    
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        //cidr_blocks = ["0.0.0.0/0"]
        security_groups = ["${aws_security_group.sg1.id}"]
    }
    
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
        Name = "sg2"
    }
}

#TAKING INPUT FOR THE KEY VARIABLE
variable "insert_key_var" {
     type = string
}


#LAUNCHING THE INSTANCES USING THESE SECURITY GROUPS
#LAUNCHING WORDPRESS INSTANCE IN SUBNET1
resource "aws_instance" "wpinst" {
    depends_on = [
        aws_security_group.sg1
    ]
    ami = "ami-0c463ba4a3f73ed7c"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.t3sub1.id}"
    vpc_security_group_ids = ["${aws_security_group.sg1.id}"]
    key_name = "${var.insert_key_var}"
    tags = {
        Name = "wpubuntu"
    }
}

#LAUNCHING MYSQL INSTANCE IN SUBNET2
resource "aws_instance" "mysqlinst" {
    depends_on = [
        aws_security_group.sg2
    ]
    ami = "ami-0dc5be0c1af834fc1"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.t3sub2.id}"
    vpc_security_group_ids = ["${aws_security_group.sg2.id}"]
    key_name = "${var.insert_key_var}"
    tags = {
        Name = "mysqlubunt"
    }
}

#RUNNING CHROME FROM THE BASE WINDOWS
resource "null_resource" "runchrome" {
    depends_on = [
        aws_instance.mysqlinst
    ]
    provisioner "local-exec" {
        command = "start chrome ${aws_instance.wpinst.public_dns}"
    }
}

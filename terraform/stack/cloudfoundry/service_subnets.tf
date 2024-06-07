/*
 * Variables required:
 *  stack_description
 *  az1
 *  az2
 *  services_cidr_1
 *  services_cidr_2
 *  vpc_id
 *  private_route_table_az1
 *  private_route_table_az2
 *
 */

resource "aws_subnet" "az1_services" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = module.vpc.private_cidrs[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.stack_description} (Services AZ1)"
  }
}

resource "aws_subnet" "az2_services" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = module.vpc.private_cidrs[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${var.stack_description} (Services AZ2)"
  }
}

resource "aws_route_table_association" "az1_services_rta" {
  subnet_id      = aws_subnet.az1_services.id
  route_table_id = module.vpc.private_route_table_ids[0]
}

resource "aws_route_table_association" "az2_services_rta" {
  subnet_id      = aws_subnet.az2_services.id
  route_table_id = module.vpc.private_route_table_ids[1]
}


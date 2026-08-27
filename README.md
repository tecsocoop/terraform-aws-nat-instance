# terraform-aws-nat-instance

Terraform module that deploys a NAT instance to provide Internet egress for the
private subnets of a VPC: it creates the EC2 instance, its network interface
(with `source_dest_check = false`), an Elastic IP, the security group, and the
`0.0.0.0/0` route in the private route table pointing to the instance ENI.

Designed to be used together with the `terraform-aws-vpc` module, consuming its
outputs (`vpc_id`, `public_subnet_ids`, `private_route_table_id`).

## Requirements

| Name      | Version   |
|-----------|-----------|
| terraform | >= 1.3.7  |
| aws       | >= 5.9.0  |

## Usage

```hcl
module "nat_instance" {
  source  = "tecsocoop/nat-instance/aws"
#  version = "X.X.X" # see the latest available tag

  name                   = "sit-tecso"
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids["1a"]
  private_route_table_id = module.vpc.private_route_table_id
}
```

> [!note]
> The module creates the `0.0.0.0/0` route in the private route table (received
> via `private_route_table_id`) toward the NAT instance ENI. That route no
> longer lives in the VPC module.

<details>
<summary>Variables</summary>

| Variable                 | Description                                                        | Values                              | Default                              |
|--------------------------|--------------------------------------------------------------------|-------------------------------------|--------------------------------------|
| `name`                   | Base name for the created resources.                              | string - e.g. `sit-tecso`           | -                                    |
| `vpc_id`                 | VPC id.                                                            | string                              | -                                    |
| `public_subnet_id`       | Public subnet where the network interface is placed.              | string                              | -                                    |
| `private_route_table_id` | Private route table where the `0.0.0.0/0` route to the NAT is added. | string                           | -                                    |
| `ssh_key_name`           | AWS key pair name for SSH access (optional with SSM).             | string                              | `null`                               |
| `ami_id`                 | AMI for the instance.                                             | string                              | `ami-07e37c8abeea5202c` (Debian 13)  |
| `instance_type`          | Instance type.                                                    | string                              | `t3a.nano`                           |
| `region`                 | AWS region, used for the SSM agent download endpoint.            | string                              | `us-east-1`                          |
| `tags`                   | Additional tags applied to all resources created by the module.  | map(string)                          | `{}`                                 |

</details>

<details>
<summary>Outputs</summary>

| Output                 | Description                                             |
|------------------------|---------------------------------------------------------|
| `network_interface_id` | Network interface id of the NAT.                        |
| `instance_id`          | NAT instance id (to connect via SSM).                   |

</details>

## Connecting via SSM Session Manager

The NAT instance is managed without SSH or open ports using AWS Systems Manager
Session Manager. The module leaves everything ready:

### Local machine requirements

- AWS CLI v2.
- Session Manager plugin for the AWS CLI:
  https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

### Connecting

```bash
aws ssm start-session --target <instance_id> --region us-east-1
```

Where `<instance_id>` is the module `instance_id` output:

```bash
terraform output -raw instance_id
```

It can also be started from the console: EC2 > select the instance >
**Connect** > **Session Manager** tab > **Connect**.

> [!note]
> The IAM user/role invoking the session needs SSM permissions
> (`ssm:StartSession`, etc.). See:
> https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html

General Session Manager reference:
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html

## License

Licensed under the [Apache-2.0](LICENSE) license.

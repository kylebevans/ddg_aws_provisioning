# perl_aws_provisioning
Provision an AWS Stack

-Tested on macOS 10.13.5, perl 5.16.3

-Assumes AWS credentials are in ~/.aws/credentials

-Assumes region is us-east-2

-Depends on PAWS: https://metacpan.org/release/Paws

```
perl aws_arch.pl
```

Creates the infrastructure to host a small Perl application that displays the Lumin Digital homepage.

-Creates a key pair.
-Creates a VPC.
-Sets up subnets and routing.
-Creates a frontend Application Load Balancer available over IPv4 and IPV6.
-Creates a backend autoscaling group available in all three availability zones.
-Provisions Ubuntu 16.04 LTS EC2 instances using cloud-init, cfn-init, and chef-solo.
-Deploys a Perl app hosted with NGINX and uwsgi that displays the web page.
-Sets up security groups.
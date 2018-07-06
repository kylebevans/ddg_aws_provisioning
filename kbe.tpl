{
  "Parameters": {
    "KeyName": {
      "Description": "Name of an existing EC2 KeyPair to enable SSH access to the instance",
      "Type": "String"
    }
  },
  "Mappings": {
    "RegionMap": {
      "us-east-2": {
        "AMI": "ami-916f59f4"
      },
      "us-west-2": {
        "AMI": "ami-4e79ed36"
      }
    },
    "AZMap": {
      "us-east-2": {
        "AZa": "us-east-2a",
        "AZb": "us-east-2b",
        "AZc": "us-east-2c"
      },
      "us-west-2": {
        "AZa": "us-west-2a",
        "AZb": "us-west-2b",
        "AZc": "us-west-2c"
      }
    }
  },
  "Resources": {
    "kbeVPC" : {
         "Type" : "AWS::EC2::VPC",
         "Properties" : {
          "CidrBlock" : "10.0.0.0/16",
    	    "EnableDnsSupport" : "true",
    	    "EnableDnsHostnames" : "true",
          "InstanceTenancy" : "default"
         }
    },
    "kbeRouteTable" : {
      "Type" : "AWS::EC2::RouteTable",
      "Properties" : {
        "VpcId" : { "Ref" : "kbeVPC" }
      }
    },
    "kbeIpv6VPCCidrBlock": {
      "Type": "AWS::EC2::VPCCidrBlock",
      "Properties": {
        "AmazonProvidedIpv6CidrBlock": true,
        "VpcId": { "Ref" : "kbeVPC" }
      }
    },
    "kbeSubnetA": {
      "Type" : "AWS::EC2::Subnet",
      "DependsOn" : "kbeIpv6VPCCidrBlock",
      "Properties" : {
        "VpcId" : { "Ref" : "kbeVPC" },
        "CidrBlock" : "10.0.0.0/20",
        "Ipv6CidrBlock": {
          "Fn::Select": [
            0, {
              "Fn::Cidr": [ { "Fn::Select": [ 0, { "Fn::GetAtt": [ "kbeVPC", "Ipv6CidrBlocks" ] } ] }, "256", "64" ]
            }
          ]
        },
        "AvailabilityZone" : {
          "Fn::FindInMap": [
            "AZMap",
            {
              "Ref": "AWS::Region"
            },
            "AZa"
          ]
        }
      }
    },
    "kbeSubnetB": {
      "Type" : "AWS::EC2::Subnet",
      "DependsOn" : "kbeIpv6VPCCidrBlock",
      "Properties" : {
        "VpcId" : { "Ref" : "kbeVPC" },
        "CidrBlock" : "10.0.16.0/20",
        "Ipv6CidrBlock": {
          "Fn::Select": [
            1, {
              "Fn::Cidr": [ { "Fn::Select": [ 0, { "Fn::GetAtt": [ "kbeVPC", "Ipv6CidrBlocks" ] } ] }, "256", "64" ]
            }
          ]
        },
        "AvailabilityZone" : {
          "Fn::FindInMap": [
            "AZMap",
            {
              "Ref": "AWS::Region"
            },
            "AZb"
          ]
        }
      }
    },
    "kbeSubnetC": {
      "Type" : "AWS::EC2::Subnet",
      "DependsOn" : "kbeIpv6VPCCidrBlock",
      "Properties" : {
        "VpcId" : { "Ref" : "kbeVPC" },
        "CidrBlock" : "10.0.32.0/20",
        "Ipv6CidrBlock": {
          "Fn::Select": [
            2, {
              "Fn::Cidr": [ { "Fn::Select": [ 0, { "Fn::GetAtt": [ "kbeVPC", "Ipv6CidrBlocks" ] } ] }, "256", "64" ]
            }
          ]
        },
        "AvailabilityZone" : {
          "Fn::FindInMap": [
            "AZMap",
            {
              "Ref": "AWS::Region"
            },
            "AZc"
          ]
        }
      }
    },
    "kbeSubnetARouteTableAssociation" : {
      "Type" : "AWS::EC2::SubnetRouteTableAssociation",
      "Properties" : {
        "SubnetId" : { "Ref" : "kbeSubnetA" },
        "RouteTableId" : { "Ref" : "kbeRouteTable" }
      }
    },
    "kbeSubnetBRouteTableAssociation" : {
      "Type" : "AWS::EC2::SubnetRouteTableAssociation",
      "Properties" : {
        "SubnetId" : { "Ref" : "kbeSubnetB" },
        "RouteTableId" : { "Ref" : "kbeRouteTable" }
      }
    },
    "kbeSubnetCRouteTableAssociation" : {
      "Type" : "AWS::EC2::SubnetRouteTableAssociation",
      "Properties" : {
        "SubnetId" : { "Ref" : "kbeSubnetC" },
        "RouteTableId" : { "Ref" : "kbeRouteTable" }
      }
    },
    "kbeGateway": {
      "Type" : "AWS::EC2::InternetGateway"
    },
    "kbeGatewayAttachment": {
      "Type" : "AWS::EC2::VPCGatewayAttachment",
      "Properties" : {
        "VpcId" : { "Ref" : "kbeVPC" },
        "InternetGatewayId" : { "Ref" : "kbeGateway" }
      }
    },
    "kbeIPv4DefaultRoute" : {
      "Type" : "AWS::EC2::Route",
      "DependsOn" : "kbeGatewayAttachment",
      "Properties" : {
        "RouteTableId" : { "Ref" : "kbeRouteTable" },
        "DestinationCidrBlock" : "0.0.0.0/0",
        "GatewayId" : { "Ref" : "kbeGateway" }
      }
    },
    "kbeIPv6DefaultRoute" : {
      "Type" : "AWS::EC2::Route",
      "DependsOn" : "kbeGatewayAttachment",
      "Properties" : {
        "RouteTableId" : { "Ref" : "kbeRouteTable" },
        "DestinationIpv6CidrBlock" : "::/0",
        "GatewayId" : { "Ref" : "kbeGateway" }
      }
    },
    "kbeIPv6SearchElasticLoadBalancer" : {
      "Type" : "AWS::ElasticLoadBalancingV2::LoadBalancer",
      "DependsOn" : "kbeGatewayAttachment",
      "Properties": {
        "Name" : "kbeIPv6SearchElasticLoadBalancer",
        "Scheme" : "internet-facing",
        "Subnets" : [ {"Ref": "kbeSubnetA"}, {"Ref" : "kbeSubnetB"}, {"Ref" : "kbeSubnetC"} ],
        "SecurityGroups": [ {"Ref": "kbeALBSecurityGroup"} ],
        "Type": "application",
        "IpAddressType": "dualstack"
      }
    },
    "kbeIPv6SearchTargetGroup" : {
      "Type" : "AWS::ElasticLoadBalancingV2::TargetGroup",
      "Properties" : {
        "HealthCheckIntervalSeconds": 30,
        "HealthCheckPath" : "/",
        "HealthCheckProtocol": "HTTP",
        "HealthCheckTimeoutSeconds": 10,
        "HealthyThresholdCount": 4,
        "Matcher" : {
          "HttpCode" : "200"
        },
        "Name": "kbeIPv6SearchTargetGroup",
        "Port": 80,
        "Protocol": "HTTP",
        "UnhealthyThresholdCount": 4,
        "VpcId": {"Ref" : "kbeVPC"}
      }
    },
    "kbeIPv6SearchListener": {
      "Type": "AWS::ElasticLoadBalancingV2::Listener",
      "Properties": {
        "DefaultActions": [{
          "Type": "forward",
          "TargetGroupArn": { "Ref": "kbeIPv6SearchTargetGroup" }
        }],
        "LoadBalancerArn": { "Ref": "kbeIPv6SearchElasticLoadBalancer" },
        "Port": "80",
        "Protocol": "HTTP"
      }
    },
    "kbeIPv6SearchWebServerGroup" : {
      "Type" : "AWS::AutoScaling::AutoScalingGroup",
      "DependsOn" : "kbeGatewayAttachment",
      "Properties" : {
        "AutoScalingGroupName" : "kbeIPv6WebServerGroup",
        "AvailabilityZones" : { "Fn::GetAZs" : { "Ref" : "AWS::Region" } },
        "Cooldown" : "300",
        "LaunchConfigurationName" : { "Ref" : "kbeIPv6SearchLaunchConfig" },
        "MinSize" : "2",
        "MaxSize" : "6",
        "DesiredCapacity" : "4",
        "HealthCheckGracePeriod" : "600",
        "HealthCheckType" : "ELB",
        "TargetGroupARNs": [ { "Ref": "kbeIPv6SearchTargetGroup" } ],
        "VPCZoneIdentifier" : [ {"Ref": "kbeSubnetA"}, {"Ref" : "kbeSubnetB"}, {"Ref" : "kbeSubnetC"} ]
      },
      "CreationPolicy" : {
        "ResourceSignal" : {
          "Timeout" : "PT15M"
        }
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "1",
          "MaxBatchSize": "1",
          "PauseTime" : "PT15M",
          "WaitOnResourceSignals": "true"
        }
      }
    },
    "kbeIPv6SearchLaunchConfig": {
      "Type" : "AWS::AutoScaling::LaunchConfiguration",
      "DependsOn" : "kbeGatewayAttachment",
      "Metadata" : {
        "AWS::CloudFormation::Init" : {
          "config" : {
            "packages" : {
              "apt" : {
                "chef" : []
              }
            },
            "sources" : {
              "/var/chef/cookbooks/kbe_perl_app" : "https://github.com/kylebevans/kbe_perl_app/tarball/master",
              "/var/chef/cookbooks/kbe_role_ubuntu_1604_base" : "https://github.com/kylebevans/kbe_role_ubuntu_1604_base/tarball/master",
              "/var/chef/cookbooks/kbe_login_banner" : "https://github.com/kylebevans/kbe_login_banner/tarball/master",
              "/var/chef/cookbooks/kbe_ssh" : "https://github.com/kylebevans/kbe_ssh/tarball/master",
              "/var/chef/cookbooks/kbe_perl" : "https://github.com/kylebevans/kbe_perl/tarball/master",
              "/var/chef/cookbooks/kbe_nginx" : "https://github.com/kylebevans/kbe_nginx/tarball/master",
              "/var/chef/cookbooks/kbe_rsyslog" : "https://github.com/kylebevans/kbe_rsyslog/tarball/master"

            },
            "files" : {
              "/var/chef/solo.rb" : {
                "content" : { "Fn::Join" : ["", [
                  "root = File.absolute_path(File.dirname(__FILE__))\n",
                  "\n",
                  "file_cache_path root\n",
                  "cookbook_path root + '/cookbooks'\n"
                ]]},
                "mode"  : "000644",
                "owner" : "root",
                "group" : "root"
              },
              "/var/chef/solo.json" : {
                "content" : { "Fn::Join" : ["", [
                  "{\n",
                  "\"run_list\": [ \"recipe[kbe_perl_app]\" ]\n",
                  "}"
                ]]},
                "mode"  : "000644",
                "owner" : "root",
                "group" : "root"
              }
            },
            "commands" : {
              "apt_update_upgrade" : {
                "command" : "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"
              },
              "run_chef" : {
                "command" : "chef-solo -c /var/chef/solo.rb -j /var/chef/solo.json -L /var/log/chef/chef-solo.log"
              }
            }
          }
        }
      },
      "Properties": {
        "KeyName": {
          "Ref": "KeyName"
        },
        "AssociatePublicIpAddress" : "true",
        "ImageId": {
          "Fn::FindInMap": [
            "RegionMap",
            {
              "Ref": "AWS::Region"
            },
            "AMI"
          ]
        },
        "InstanceMonitoring" : "false",
        "InstanceType": "t2.micro",
        "SecurityGroups": [ { "Ref": "kbeIPv6SearchSecurityGroup" } ],
        "UserData"       : { "Fn::Base64" : { "Fn::Join" : ["", [
          "#!/bin/bash -xe\n",

          "apt-get -y update\n",
          "DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade\n",
          
          "apt-get -y install python-setuptools\n",
          "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n",
          "ln -s /root/aws-cfn-bootstrap-latest/init/ubuntu/cfn-hup /etc/init.d/cfn-hup\n",
            
          "/usr/local/bin/cfn-init -v ",
          "         --stack ", { "Ref" : "AWS::StackName" },
          "         --resource kbeIPv6SearchLaunchConfig ",
          "         --region ", { "Ref" : "AWS::Region" }, "\n",

          "/usr/local/bin/cfn-signal -e $? ",
          "         --stack ", { "Ref" : "AWS::StackName" },
          "         --resource kbeIPv6SearchWebServerGroup ",
          "         --region ", { "Ref" : "AWS::Region" }, "\n"
        ]]}}
      }
    },
    "kbeIPv6SearchSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Enable SSH access via port 22",
        "VpcId": { "Ref" : "kbeVPC" },
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": "22",
            "ToPort": "22",
            "CidrIp": "164.107.68.164/31"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "22",
            "ToPort": "22",
            "CidrIp": "50.4.40.89/32"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "80",
            "ToPort": "80",
            "SourceSecurityGroupId" : { "Ref" : "kbeALBSecurityGroup" }
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "SourceSecurityGroupId" : { "Ref" : "kbeALBSecurityGroup" }
          }
        ]
      }
    },
    "kbeALBSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Enable http/https",
        "VpcId": { "Ref" : "kbeVPC" },
        "SecurityGroupIngress": [
          {
            "IpProtocol": "tcp",
            "FromPort": "80",
            "ToPort": "80",
            "CidrIp": "0.0.0.0/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "CidrIp": "0.0.0.0/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "80",
            "ToPort": "80",
            "CidrIpv6": "::/0"
          },
          {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "CidrIpv6": "::/0"
          }
        ]
      }
    }
  },
  "Outputs" : {
    "URL": {
      "Description": "URL of the website",
      "Value": { "Fn::Join": [ "", [ "http://", { "Fn::GetAtt": [ "kbeIPv6SearchElasticLoadBalancer", "DNSName" ] } ] ] }
    }
  }
}

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
    "ddgVPC" : {
         "Type" : "AWS::EC2::VPC",
         "Properties" : {
          "CidrBlock" : "10.0.0.0/16",
    	    "EnableDnsSupport" : "true",
    	    "EnableDnsHostnames" : "true",
          "InstanceTenancy" : "default"
         }
    },
    "ddgRouteTable" : {
      "Type" : "AWS::EC2::RouteTable",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgVPC" }
      }
    },
    "ddgSubnetA": {
      "Type" : "AWS::EC2::Subnet",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgVPC" },
        "CidrBlock" : "10.0.0.0/20",
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
    "ddgSubnetB": {
      "Type" : "AWS::EC2::Subnet",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgVPC" },
        "CidrBlock" : "10.0.16.0/20",
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
    "ddgSubnetC": {
      "Type" : "AWS::EC2::Subnet",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgVPC" },
        "CidrBlock" : "10.0.32.0/20",
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
    "ddgSubnetARouteTableAssociation" : {
      "Type" : "AWS::EC2::SubnetRouteTableAssociation",
      "Properties" : {
        "SubnetId" : { "Ref" : "ddgSubnetA" },
        "RouteTableId" : { "Ref" : "ddgRouteTable" }
      }
    },
    "ddgSubnetBRouteTableAssociation" : {
      "Type" : "AWS::EC2::SubnetRouteTableAssociation",
      "Properties" : {
        "SubnetId" : { "Ref" : "ddgSubnetB" },
        "RouteTableId" : { "Ref" : "ddgRouteTable" }
      }
    },
    "ddgSubnetCRouteTableAssociation" : {
      "Type" : "AWS::EC2::SubnetRouteTableAssociation",
      "Properties" : {
        "SubnetId" : { "Ref" : "ddgSubnetC" },
        "RouteTableId" : { "Ref" : "ddgRouteTable" }
      }
    },
    "ddgIpv6VPCCidrBlock": {
      "Type": "AWS::EC2::VPCCidrBlock",
      "Properties": {
        "AmazonProvidedIpv6CidrBlock": true,
        "VpcId": { "Ref" : "ddgVPC" }
      }
    },
    "ddgGateway": {
      "Type" : "AWS::EC2::InternetGateway"
    },
    "ddgGatewayAttachment": {
      "Type" : "AWS::EC2::VPCGatewayAttachment",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgVPC" },
        "InternetGatewayId" : { "Ref" : "ddgGateway" }
      }
    },
    "ddgDefaultRoute" : {
      "Type" : "AWS::EC2::Route",
      "DependsOn" : "ddgGatewayAttachment",
      "Properties" : {
        "RouteTableId" : { "Ref" : "ddgRouteTable" },
        "DestinationCidrBlock" : "0.0.0.0/0",
        "GatewayId" : { "Ref" : "ddgGateway" }
      }
    },
    "ddgIPv6SearchElasticLoadBalancer" : {
      "Type" : "AWS::ElasticLoadBalancingV2::LoadBalancer",
      "DependsOn" : "ddgGatewayAttachment",
      "Properties": {
        "Name" : "ddgIPv6SearchElasticLoadBalancer",
        "Scheme" : "internet-facing",
        "Subnets" : [ {"Ref": "ddgSubnetA"}, {"Ref" : "ddgSubnetB"}, {"Ref" : "ddgSubnetC"} ],
        "SecurityGroups": [ {"Ref": "ddgALBSecurityGroup"} ],
        "Type": "application",
        "IpAddressType": "dualstack"
      }
    },
    "ddgIPv6SearchTargetGroup" : {
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
        "Name": "ddgIPv6SearchTargetGroup",
        "Port": 80,
        "Protocol": "HTTPS",
        "UnhealthyThresholdCount": 4,
        "VpcId": {"Ref" : "ddgVPC"}
      }
    },
    "ddgIPv6SearchListener": {
      "Type": "AWS::ElasticLoadBalancingV2::Listener",
      "Properties": {
        "DefaultActions": [{
          "Type": "forward",
          "TargetGroupArn": { "Ref": "ddgIPv6SearchTargetGroup" }
        }],
        "LoadBalancerArn": { "Ref": "ddgIPv6SearchElasticLoadBalancer" },
        "Port": "80",
        "Protocol": "HTTP"
      }
    },
    "ddgIPv6SearchWebServerGroup" : {
      "Type" : "AWS::AutoScaling::AutoScalingGroup",
      "DependsOn" : "ddgGatewayAttachment",
      "Properties" : {
        "AutoScalingGroupName" : "ddgIPv6WebServerGroup",
        "AvailabilityZones" : { "Fn::GetAZs" : { "Ref" : "AWS::Region" } },
        "Cooldown" : "300",
        "LaunchConfigurationName" : { "Ref" : "ddgIPv6SearchLaunchConfig" },
        "MinSize" : "2",
        "MaxSize" : "6",
        "DesiredCapacity" : "4",
        "HealthCheckGracePeriod" : "600",
        "HealthCheckType" : "ELB",
        "TargetGroupARNs": [ { "Ref": "ddgIPv6SearchTargetGroup" } ]
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

    "ddgIPv6SearchLaunchConfig": {
      "Type" : "AWS::AutoScaling::LaunchConfiguration",
      "Metadata" : {
        "AWS::CloudFormation::Init" : {
          "config" : {
            "packages" : {
              "apt" : {
                "apt-transport-https" : []
              },
              "chef" : {
                "chef" : []
              }
            },
            "sources" : {
              "/var/chef/cookbooks/kbe_ddg_search" : "https://github.com/kylebevans/kbe_ddg_search/tarball/master",
              "/var/chef/cookbooks/kbe_ddg_search" : "https://github.com/kylebevans/kbe_role_ubuntu_1604_base/tarball/master",
              "/var/chef/cookbooks/kbe_ddg_search" : "https://github.com/kylebevans/kbe_login_banner/tarball/master",
              "/var/chef/cookbooks/kbe_ddg_search" : "https://github.com/kylebevans/kbe_ssh/tarball/master"
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
                  "\"run_list\": [ \"recipe[kbe_ddg_search]\" ]\n",
                  "}"
                ]]},
                "mode"  : "000644",
                "owner" : "root",
                "group" : "root"
              }
            },
            "commands" : {
              "apt_update_upgrade" : {
                "command" : "apt-get update && apt-get -y upgrade"
              },
              "run_chef" : {
                "command" : "chef-solo -c solo.rb -j solo.json"
              }
            }
          }
        }
      },
      "Properties": {
        "KeyName": {
          "Ref": "KeyName"
        },
        "ImageId": {
          "Fn::FindInMap": [
            "RegionMap",
            {
              "Ref": "AWS::Region"
            },
            "AMI"
          ]
        },
        "InstanceType": "t2.micro",
        "NetworkInterfaces" : [{
          "AssociatePublicIpAddress" : "true",
          "DeviceIndex"              : "0",
          "DeleteOnTermination"      : "true",
          "SubnetId"                 : { "Ref" : "ddgSubnetA" },
          "GroupSet"                 : [{ "Ref": "ddgIPv6SearchSecurityGroup" }]
        }]
      }
    },
    "ddgIPv6SearchSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Enable SSH access via port 22",
        "VpcId": { "Ref" : "ddgVPC" },
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
          }
        ]
      }
    },
    "ddgALBSecurityGroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Enable http/https",
        "VpcId": { "Ref" : "ddgVPC" },
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
          }
        ]
      }
    },
    "Outputs": {
      "URL": {
        "Description": "URL of the website",
        "Value": { "Fn::Join": [ "", [ "http://", { "Fn::GetAtt": [ "ApplicationLoadBalancer", "DNSName" ] } ] ] }
      }
    }
  }
}
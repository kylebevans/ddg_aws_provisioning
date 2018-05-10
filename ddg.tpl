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
    "ddgChefInstance": {
      "Type": "AWS::EC2::Instance",
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
          "GroupSet"                 : [{ "Ref": "ddgChefSecurityGroup" }]
        }]
      }
    },
    "ddgChefSecurityGroup": {
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
    }
  }
}
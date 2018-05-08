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
    "ddgvpc" : {
         "Type" : "AWS::EC2::VPC",
         "Properties" : {
          "CidrBlock" : "10.0.0.0/16",
    	    "EnableDnsSupport" : "true",
    	    "EnableDnsHostnames" : "true",
          "InstanceTenancy" : "default"
         }
    },
    "ddgsubneta": {
      "Type" : "AWS::EC2::Subnet",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgvpc" },
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
    "ddgsubnetb": {
      "Type" : "AWS::EC2::Subnet",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgvpc" },
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
    "ddgsubnetc": {
      "Type" : "AWS::EC2::Subnet",
      "Properties" : {
        "VpcId" : { "Ref" : "ddgvpc" },
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
    "Ipv6VPCCidrBlock": {
      "Type": "AWS::EC2::VPCCidrBlock",
      "Properties": {
        "AmazonProvidedIpv6CidrBlock": true,
        "VpcId": { "Ref" : "ddgvpc" }
      }
    },
    "chefinstance": {
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
          "SubnetId"                 : { "Ref" : "ddgsubneta" },
          "GroupSet"                 : [{ "Ref": "chefsecuritygroup" }]
        }]
      }
    },
    "chefsecuritygroup": {
      "Type": "AWS::EC2::SecurityGroup",
      "Properties": {
        "GroupDescription": "Enable SSH access via port 22",
        "VpcId": { "Ref" : "ddgvpc" },
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
#!/usr/bin/env perl

use local::lib;
use Paws;
use Data::Printer;


# read in the cloudformation template
my $file = "ddg.tpl";
my $cftemplate;
{
    local $/;
    open my $fh, '<', $file or die "can't open $file: $!";
    $cftemplate = <$fh>;
}

my $cfddg = Paws->service('CloudFormation', region => 'us-east-2') or die "can't create CloudFormation object: $!";

@parameters = { ParameterKey => "KeyName", ParameterValue => "kylebe-key-pair-useast2" };

$parameters_ref = \@parameters;

$cfddg->CreateStack(
  Parameters => $parameters_ref,
  StackName => "ddgstack",
  TemplateBody => $cftemplate
) or die "stack creation failed: $!";

